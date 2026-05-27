const fs = require('fs');
const path = require('path');
const mysql = require('mysql2/promise');
const bcrypt = require('bcryptjs');
const logger = require('../utils/logger');

function splitStatements(sql) {
  return sql
    .split(/;\s*[\r\n]/)
    .map(s => s.replace(/^\s*(--[^\n]*\n)+/g, '').trim())
    .filter(s => s.length > 0);
}

async function ensureColumn(conn, dbName, table, column, definition) {
  const [rows] = await conn.query(
    `SELECT COLUMN_NAME FROM information_schema.COLUMNS
     WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ? AND COLUMN_NAME = ?`,
    [dbName, table, column]
  );
  if (rows.length === 0) {
    logger.info(`[initDb] Adicionando coluna ${table}.${column}`);
    await conn.query(`ALTER TABLE \`${table}\` ADD COLUMN ${definition}`);
  }
}

async function ensureIndex(conn, dbName, table, indexName, definition) {
  const [rows] = await conn.query(
    `SELECT INDEX_NAME FROM information_schema.STATISTICS
     WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ? AND INDEX_NAME = ?`,
    [dbName, table, indexName]
  );
  if (rows.length === 0) {
    logger.info(`[initDb] Criando index ${indexName} em ${table}`);
    await conn.query(definition);
  }
}

async function runSchema(conn, dbName) {
  const schemaPath = path.join(__dirname, '..', '..', 'database', 'schema.sql');
  const sql = fs.readFileSync(schemaPath, 'utf8');

  const statements = splitStatements(sql).filter(s => !/^USE\s/i.test(s));

  for (const stmt of statements) {
    try {
      await conn.query(stmt);
    } catch (err) {
      if (err.code === 'ER_DUP_KEYNAME') continue;
      throw err;
    }
  }

  await ensureColumn(conn, dbName, 'usuarios', 'turno',
    "turno ENUM('manha','tarde','noite','integral') NULL AFTER setor");
  await ensureIndex(conn, dbName, 'usuarios', 'idx_usuarios_turno',
    'CREATE INDEX idx_usuarios_turno ON usuarios(turno)');

  await ensureColumn(conn, dbName, 'audit_logs', 'recurso',
    'recurso VARCHAR(100) NULL AFTER acao');
  await ensureColumn(conn, dbName, 'audit_logs', 'recurso_id',
    'recurso_id INT NULL AFTER recurso');
  await ensureIndex(conn, dbName, 'audit_logs', 'idx_audit_logs_recurso',
    'CREATE INDEX idx_audit_logs_recurso ON audit_logs(recurso)');
}

async function runSeeds(conn) {
  const [pergCount] = await conn.query('SELECT COUNT(*) as total FROM perguntas');
  if (pergCount[0].total > 0) {
    logger.info('[initDb] Perguntas ja populadas, pulando seed');
    return;
  }

  const seedsPath = path.join(__dirname, '..', '..', 'database', 'seeds.sql');
  if (!fs.existsSync(seedsPath)) {
    logger.warn('[initDb] seeds.sql nao encontrado, pulando');
    return;
  }

  const sql = fs.readFileSync(seedsPath, 'utf8');
  const statements = splitStatements(sql);
  for (const stmt of statements) {
    await conn.query(stmt);
  }
  logger.info(`[initDb] ${statements.length} comando(s) de seed executados`);
}

async function seedAdmin(conn) {
  const [rows] = await conn.query(
    "SELECT id FROM usuarios WHERE perfil = 'administrador' LIMIT 1"
  );
  if (rows.length > 0) return;

  const email = process.env.ADMIN_EMAIL || 'admin@psicossocial.local';
  const senha = process.env.ADMIN_SENHA || 'Admin@123';
  const nome = process.env.ADMIN_NOME || 'Administrador';
  const hash = await bcrypt.hash(senha, 10);

  await conn.query(
    `INSERT INTO usuarios (nome, email, senha, cargo, perfil, setor, status)
     VALUES (?, ?, ?, 'Administrador', 'administrador', 'Geral', 'ativo')`,
    [nome, email, hash]
  );

  const isDefaultPassword = !process.env.ADMIN_SENHA;
  logger.warn(`[initDb] Administrador criado: ${email}`);
  if (isDefaultPassword) {
    logger.warn('[initDb] SENHA PADRAO em uso (Admin@123). DEFINA ADMIN_SENHA em producao!');
  }
}

async function initDb() {
  const dbName = process.env.DB_NAME || 'psicossocial_db';
  const host = process.env.DB_HOST || 'localhost';
  const port = parseInt(process.env.DB_PORT, 10) || 3306;
  const user = process.env.DB_USER || 'root';
  const password = process.env.DB_PASSWORD || '';

  let conn;
  try {
    conn = await mysql.createConnection({
      host, port, user, password,
      multipleStatements: false
    });
  } catch (err) {
    logger.error('[initDb] Falha ao conectar no MySQL', {
      code: err.code,
      message: err.message,
      host, port, user
    });
    throw err;
  }

  try {
    await conn.query(
      `CREATE DATABASE IF NOT EXISTS \`${dbName}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci`
    );
    await conn.query(`USE \`${dbName}\``);

    await runSchema(conn, dbName);
    await runSeeds(conn);
    await seedAdmin(conn);

    logger.info(`[initDb] Banco "${dbName}" pronto`);
  } finally {
    await conn.end();
  }
}

module.exports = initDb;
