import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import Database from "better-sqlite3";
import * as path from "path";
import * as os from "os";
import { z } from "zod";

const DB_PATH =
  process.env.IMESSAGE_DB_PATH ||
  path.join(os.homedir(), "Library/Messages/chat.db");

function getDb(): Database.Database {
  return new Database(DB_PATH, { readonly: true });
}

/**
 * Apple Core Data timestamps start from 2001-01-01.
 * They are stored in nanoseconds. To convert to Unix:
 *   unix = (core_data_timestamp / 1_000_000_000) + 978307200
 */
const DATE_EXPR = `datetime(message.date / 1000000000 + 978307200, 'unixepoch', 'localtime')`;

/**
 * Filter clause for messages within the last N days.
 */
function daysBackClause(daysBack: number): string {
  const secondsBack = daysBack * 86400;
  return `(message.date / 1000000000 + 978307200) > (strftime('%s', 'now') - ${secondsBack})`;
}

/**
 * Filter clause for messages within the last N hours.
 */
function hoursBackClause(hours: number): string {
  const secondsBack = hours * 3600;
  return `(message.date / 1000000000 + 978307200) > (strftime('%s', 'now') - ${secondsBack})`;
}

const BASE_QUERY = `
  SELECT
    ${DATE_EXPR} AS date,
    message.text AS text,
    message.is_from_me AS is_from_me,
    chat.chat_identifier AS chat_identifier,
    COALESCE(handle.id, 'me') AS sender
  FROM message
  JOIN chat_message_join ON message.ROWID = chat_message_join.message_id
  JOIN chat ON chat.ROWID = chat_message_join.chat_id
  LEFT JOIN handle ON message.handle_id = handle.ROWID
`;

function contactFilter(paramName: string): string {
  return `(chat.chat_identifier LIKE @${paramName} OR handle.id LIKE @${paramName})`;
}

// ── MCP Server ──────────────────────────────────────────────────────────────

const server = new McpServer({
  name: "imessage-mcp",
  version: "1.0.0",
});

// ── Tool: search_messages ───────────────────────────────────────────────────

server.tool(
  "search_messages",
  "Search iMessage history by text content, optionally filtered by contact",
  {
    query: z.string().describe("Text to search for in messages"),
    contact: z
      .string()
      .optional()
      .describe("Phone number or email to filter by"),
    limit: z
      .number()
      .int()
      .min(1)
      .max(100)
      .default(50)
      .describe("Max results to return (default 50, max 100)"),
    days_back: z
      .number()
      .int()
      .min(1)
      .default(30)
      .describe("How many days back to search (default 30)"),
  },
  async ({ query, contact, limit, days_back }) => {
    const db = getDb();
    try {
      const conditions: string[] = [
        "message.text LIKE @query",
        daysBackClause(days_back),
      ];
      const params: Record<string, string | number> = {
        query: `%${query}%`,
      };

      if (contact) {
        conditions.push(contactFilter("contact"));
        params.contact = `%${contact}%`;
      }

      const sql = `${BASE_QUERY} WHERE ${conditions.join(" AND ")} ORDER BY message.date DESC LIMIT @limit`;
      params.limit = limit;

      const rows = db.prepare(sql).all(params);
      return {
        content: [{ type: "text" as const, text: JSON.stringify(rows, null, 2) }],
      };
    } finally {
      db.close();
    }
  }
);

// ── Tool: get_recent_messages ───────────────────────────────────────────────

server.tool(
  "get_recent_messages",
  "Get recent iMessages, optionally filtered by contact",
  {
    hours: z
      .number()
      .int()
      .min(1)
      .max(168)
      .default(24)
      .describe("How many hours back to look (default 24, max 168)"),
    contact: z
      .string()
      .optional()
      .describe("Phone number or email to filter by"),
    limit: z
      .number()
      .int()
      .min(1)
      .max(100)
      .default(50)
      .describe("Max results to return (default 50, max 100)"),
  },
  async ({ hours, contact, limit }) => {
    const db = getDb();
    try {
      const conditions: string[] = [hoursBackClause(hours)];
      const params: Record<string, string | number> = {};

      if (contact) {
        conditions.push(contactFilter("contact"));
        params.contact = `%${contact}%`;
      }

      const sql = `${BASE_QUERY} WHERE ${conditions.join(" AND ")} ORDER BY message.date DESC LIMIT @limit`;
      params.limit = limit;

      const rows = db.prepare(sql).all(params);
      return {
        content: [{ type: "text" as const, text: JSON.stringify(rows, null, 2) }],
      };
    } finally {
      db.close();
    }
  }
);

// ── Tool: list_conversations ────────────────────────────────────────────────

server.tool(
  "list_conversations",
  "List recent iMessage conversations with last message preview",
  {
    limit: z
      .number()
      .int()
      .min(1)
      .max(50)
      .default(20)
      .describe("Max conversations to return (default 20, max 50)"),
  },
  async ({ limit }) => {
    const db = getDb();
    try {
      const sql = `
        SELECT
          chat.chat_identifier AS chat_identifier,
          chat.display_name AS display_name,
          latest_msg.text AS last_message,
          datetime(latest_msg.date / 1000000000 + 978307200, 'unixepoch', 'localtime') AS last_date,
          cnt.message_count AS message_count
        FROM chat
        JOIN (
          SELECT chat_message_join.chat_id, MAX(message.ROWID) AS max_rowid
          FROM message
          JOIN chat_message_join ON message.ROWID = chat_message_join.message_id
          GROUP BY chat_message_join.chat_id
        ) AS latest ON latest.chat_id = chat.ROWID
        JOIN message AS latest_msg ON latest_msg.ROWID = latest.max_rowid
        JOIN (
          SELECT chat_message_join.chat_id, COUNT(*) AS message_count
          FROM chat_message_join
          GROUP BY chat_message_join.chat_id
        ) AS cnt ON cnt.chat_id = chat.ROWID
        ORDER BY latest_msg.date DESC
        LIMIT @limit
      `;

      const rows = db.prepare(sql).all({ limit });
      return {
        content: [{ type: "text" as const, text: JSON.stringify(rows, null, 2) }],
      };
    } finally {
      db.close();
    }
  }
);

// ── Tool: extract_action_items ──────────────────────────────────────────────

const ACTION_PATTERNS: { pattern: RegExp; reason: string }[] = [
  { pattern: /can you/i, reason: 'Contains "can you" request' },
  { pattern: /could you/i, reason: 'Contains "could you" request' },
  { pattern: /please\b/i, reason: 'Contains "please" request' },
  { pattern: /don'?t forget/i, reason: 'Contains "don\'t forget" reminder' },
  { pattern: /remind me/i, reason: 'Contains "remind me" request' },
  { pattern: /need to/i, reason: 'Contains "need to" obligation' },
  { pattern: /have to/i, reason: 'Contains "have to" obligation' },
  { pattern: /should\b/i, reason: 'Contains "should" suggestion' },
  { pattern: /\btodo\b/i, reason: 'Contains "todo" keyword' },
  { pattern: /pick up/i, reason: 'Contains "pick up" task' },
  { pattern: /\bbring\b/i, reason: 'Contains "bring" request' },
];

function detectActionReason(
  text: string,
  isFromMe: number
): string | null {
  if (!text) return null;

  for (const { pattern, reason } of ACTION_PATTERNS) {
    if (pattern.test(text)) return reason;
  }

  // Questions from others may be action items
  if (isFromMe === 0 && text.includes("?")) {
    return "Question from contact (may need response)";
  }

  return null;
}

server.tool(
  "extract_action_items",
  "Extract potential action items and requests from recent iMessages using heuristic detection",
  {
    hours: z
      .number()
      .int()
      .min(1)
      .max(168)
      .default(48)
      .describe("How many hours back to scan (default 48, max 168)"),
    contact: z
      .string()
      .optional()
      .describe("Phone number or email to filter by"),
  },
  async ({ hours, contact }) => {
    const db = getDb();
    try {
      const conditions: string[] = [
        hoursBackClause(hours),
        "message.text IS NOT NULL",
        "message.text != ''",
      ];
      const params: Record<string, string | number> = {};

      if (contact) {
        conditions.push(contactFilter("contact"));
        params.contact = `%${contact}%`;
      }

      const sql = `${BASE_QUERY} WHERE ${conditions.join(" AND ")} ORDER BY message.date DESC`;

      const rows = db.prepare(sql).all(params) as Array<{
        date: string;
        text: string;
        is_from_me: number;
        chat_identifier: string;
        sender: string;
      }>;

      const actionItems = [];
      for (const row of rows) {
        const reason = detectActionReason(row.text, row.is_from_me);
        if (reason) {
          actionItems.push({
            text: row.text,
            sender: row.sender,
            date: row.date,
            chat_identifier: row.chat_identifier,
            reason,
          });
        }
      }

      return {
        content: [
          { type: "text" as const, text: JSON.stringify(actionItems, null, 2) },
        ],
      };
    } finally {
      db.close();
    }
  }
);

// ── Start server ────────────────────────────────────────────────────────────

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error("iMessage MCP server running on stdio");
}

main().catch((err) => {
  console.error("Fatal error:", err);
  process.exit(1);
});
