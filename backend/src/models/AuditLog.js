const pool = require('../config/database');
const logger = require('../utils/logger');

class AuditLog {
  static async create({ usuario_id, acao, recurso = null, recurso_id = null, detalhes = null, ip = null }) {
    try {
      await pool.execute(
        `INSERT INTO audit_logs (usuario_id, acao, recurso, recurso_id, detalhes, ip)
         VALUES (?, ?, ?, ?, ?, ?)`,
        [usuario_id || null, acao, recurso, recurso_id, detalhes, ip]
      );
    } catch (err) {
      logger.error('[AuditLog] Falha ao registrar evento', {
        acao, recurso, recurso_id, error: err.message
      });
    }
  }

  static async findRecent({ usuario_id, acao, recurso, limit = 100, offset = 0 } = {}) {
    let query = 'SELECT * FROM audit_logs WHERE 1=1';
    const params = [];

    if (usuario_id) { query += ' AND usuario_id = ?'; params.push(usuario_id); }
    if (acao) { query += ' AND acao = ?'; params.push(acao); }
    if (recurso) { query += ' AND recurso = ?'; params.push(recurso); }

    query += ' ORDER BY created_at DESC LIMIT ? OFFSET ?';
    params.push(limit, offset);

    const [rows] = await pool.execute(query, params);
    return rows;
  }

  static log(req, { acao, recurso = null, recurso_id = null, detalhes = null }) {
    return this.create({
      usuario_id: req.user ? req.user.id : null,
      acao,
      recurso,
      recurso_id,
      detalhes,
      ip: req.ip || req.headers['x-forwarded-for'] || req.connection?.remoteAddress || null
    });
  }
}

module.exports = AuditLog;
