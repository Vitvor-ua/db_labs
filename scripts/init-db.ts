import { readFileSync } from "fs";
import { Client } from "pg";
import dotenv from "dotenv";

// ✅ Завантаження .env з правильного шляху
dotenv.config({ path: "./src/api/.env" });

// ✅ Додатково можна вивести URL для перевірки
if (!process.env.DATABASE_URL) {
  throw new Error("❌ DATABASE_URL is not defined. Check your .env path.");
} else {
  console.log("✅ Loaded DATABASE_URL:", process.env.DATABASE_URL);
}

const sql = readFileSync("init.sql", "utf-8");
const client = new Client({
  connectionString: process.env.DATABASE_URL,
});

async function main() {
  try {
    await client.connect();
    console.log("✅ Connected to database.");
    await client.query(sql);
    console.log("✅ SQL script executed successfully.");
  } catch (err) {
    console.error("❌ Error initializing DB:", err);
  } finally {
    await client.end();
  }
}

main();
