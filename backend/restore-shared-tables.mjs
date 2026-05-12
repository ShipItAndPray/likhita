// Recreate the chain911 + rocket-merch tables that drizzle-kit push
// accidentally dropped. Tables only — data is not restored here.
// For data recovery, use Neon's Point-In-Time Recovery (Branch From
// History) in the Neon console.
import { neon } from "@neondatabase/serverless";

const sql = neon(process.env.DATABASE_URL);

// chain911 tables
await sql`CREATE TABLE IF NOT EXISTS reporters (
  id VARCHAR(10) PRIMARY KEY, handle VARCHAR(100) NOT NULL, role VARCHAR(100),
  color VARCHAR(10), total_alerts INT DEFAULT 0, confirmed_alerts INT DEFAULT 0,
  false_positives INT DEFAULT 0, joined_at TIMESTAMP
)`;
await sql`CREATE TABLE IF NOT EXISTS teams (
  id VARCHAR(10) PRIMARY KEY, name VARCHAR(100) NOT NULL, type VARCHAR(50)
)`;
await sql`CREATE TABLE IF NOT EXISTS alerts (
  id VARCHAR(50) PRIMARY KEY, reporter_id VARCHAR(10), address VARCHAR(200) NOT NULL,
  chain VARCHAR(10) NOT NULL, evidence_url TEXT, description TEXT NOT NULL,
  severity VARCHAR(20) NOT NULL, status VARCHAR(20) DEFAULT 'active',
  amount VARCHAR(50), attack_type VARCHAR(100), attribution VARCHAR(100),
  enrichment JSONB, created_at TIMESTAMP DEFAULT NOW()
)`;
await sql`CREATE TABLE IF NOT EXISTS decisions (
  id VARCHAR(100) PRIMARY KEY, alert_id VARCHAR(50), team_id VARCHAR(10),
  team_name VARCHAR(100), action VARCHAR(20) NOT NULL, reason TEXT,
  decided_at TIMESTAMP DEFAULT NOW()
)`;
await sql`CREATE TABLE IF NOT EXISTS audit_log (
  id SERIAL PRIMARY KEY, type VARCHAR(50) NOT NULL, alert_id VARCHAR(50),
  actor VARCHAR(100), details TEXT, created_at TIMESTAMP DEFAULT NOW()
)`;
await sql`CREATE TABLE IF NOT EXISTS webhooks (
  id VARCHAR(10) PRIMARY KEY, team_id VARCHAR(10), type VARCHAR(20) NOT NULL,
  url TEXT NOT NULL, enabled BOOLEAN DEFAULT true
)`;

// rocket-merch waitlist
await sql`CREATE TABLE IF NOT EXISTS waitlist (
  id SERIAL PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  size TEXT DEFAULT 'M',
  created_at TIMESTAMPTZ DEFAULT NOW()
)`;

console.log("Tables recreated (empty). Data loss is not addressed here.");
