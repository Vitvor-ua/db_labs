import { readFileSync } from 'fs'
import { dirname } from 'path'
import { fileURLToPath } from 'url'
import { Client } from 'pg'
import dotenv from 'dotenv'

const __dirname = dirname(fileURLToPath(import.meta.url))

dotenv.config()

if (!process.env.DATABASE_URL) {
  throw new Error('❌ DATABASE_URL is not defined')
}

console.log('✅ Loaded DATABASE_URL:', process.env.DATABASE_URL)

const sql = readFileSync(__dirname + '/init.sql', 'utf-8')
const client = new Client({ connectionString: process.env.DATABASE_URL })

async function main() {
  try {
    await client.connect()
    console.log('✅ Connected to database.')
    await client.query(sql)
    console.log('✅ DB initialized.')
  } catch (err) {
    console.error('❌ Error initializing DB:', err)
    process.exit(1)
  } finally {
    await client.end()
  }
}

main()
