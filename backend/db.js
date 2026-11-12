const path = require('path');
const oracledb = require('oracledb');
require('dotenv').config({ path: path.resolve(__dirname, '../.env') });

// Tra ve ket qua dang Object { COL: value } va tu dong fetch CLOB/NVARCHAR2 sach se
oracledb.outFormat = oracledb.OUT_FORMAT_OBJECT;
oracledb.fetchAsString = [oracledb.CLOB];

const dbConfig = {
  user: process.env.DB_USER || 'EWALLET_APP',
  password: process.env.DB_PASSWORD || 'Ewallet2026',
  connectString: `${process.env.DB_HOST || 'localhost'}:${process.env.DB_PORT || '1521'}/${process.env.DB_SERVICE || 'FREEPDB1'}`,
  poolMin: 2,
  poolMax: 10,
  poolIncrement: 1
};

let poolPromise = null;

async function getPool() {
  if (!poolPromise) {
    poolPromise = oracledb.createPool(dbConfig).catch((err) => {
      poolPromise = null;
      throw err;
    });
  }
  return poolPromise;
}

async function getConnection() {
  const pool = await getPool();
  return pool.getConnection();
}

async function closePool() {
  if (poolPromise) {
    const pool = await poolPromise;
    await pool.close(5);
    poolPromise = null;
  }
}

module.exports = {
  oracledb,
  dbConfig,
  getPool,
  getConnection,
  closePool
};
