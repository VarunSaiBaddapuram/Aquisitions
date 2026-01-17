import "dotenv/config";

import { neon, neonConfig } from "@neondatabase/serverless";
import { drizzle } from "drizzle-orm/neon-http";

// Configure Neon for local development when using Neon Local
if (
  process.env.NODE_ENV === "development" &&
  process.env.DATABASE_URL?.includes("neon-local")
) {
  // Configure for Neon Local HTTP communication
  neonConfig.fetchEndpoint = "http://neon-local:5432/sql";
  neonConfig.useSecureWebSocket = false;
  neonConfig.poolQueryViaFetch = true;
}

const sql = neon(process.env.DATABASE_URL);
const db = drizzle(sql);

export { db, sql };
