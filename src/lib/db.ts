import sql from "mssql"
// Import TYPES from the internal datatypes module to avoid webpack module
// duplication that causes "parameter.type.validate is not a function" errors.
// eslint-disable-next-line @typescript-eslint/no-require-imports
const { TYPES } = require("mssql/lib/datatypes") as { TYPES: typeof import("mssql") }

const connectionString = process.env.DATABASE_URL

if (!connectionString) {
  throw new Error("Missing DATABASE_URL environment variable.")
}

declare global {
  var masuPool: sql.ConnectionPool | undefined
}

const poolPromise = globalThis.masuPool
  ? Promise.resolve(globalThis.masuPool)
  : new sql.ConnectionPool(connectionString).connect().then((pool) => {
      globalThis.masuPool = pool
      return pool
    })

export async function getPool() {
  return poolPromise
}

export { sql, TYPES }
