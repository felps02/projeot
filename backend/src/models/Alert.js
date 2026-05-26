const pool = require('../config/database');

class Alert {
  static async findById(id) {
    const [rows] = await pool.execute(
      `SELECT al.*, u.nome as usuario_nome, u.setor as usuario_setor
       FROM alertas al
       JOIN usuarios u ON al.usuario_id = u.id
       WHERE al.id = ?`,
      [id]
    );
    return rows[0] || null;
  }

  static async findByUser(userId, filters = {}) {
    let query = `SELECT al.*, u.nome as usuario_nome
                 FROM alertas al
                 JOIN usuarios u ON al.usuario_id = u.id
                 WHERE al.usuario_id = ?`;
    const params = [userId];

    if (filters.tipo) {
      query += ' AND al.tipo = ?';
      params.push(filters.tipo);
    }
    if (filters.lido !== undefined) {
      query += ' AND al.lido = ?';
      params.push(filters.lido);
    }

    query += ' ORDER BY al.data DESC';

    if (filters.limit) {
      query += ' LIMIT ? OFFSET ?';
      params.push(filters.limit, filters.offset || 0);
    }

    const [rows] = await pool.execute(query, params);
    return rows;
  }

  static async findUnread(userId) {
    const [rows] = await pool.execute(
      `SELECT al.*, u.nome as usuario_nome
       FROM alertas al
       JOIN usuarios u ON al.usuario_id = u.id
       WHERE al.usuario_id = ? AND al.lido = FALSE
       ORDER BY al.data DESC`,
      [userId]
    );
    return rows;
  }

  static async countUnread(userId) {
    const [rows] = await pool.execute(
      'SELECT COUNT(*) as total FROM alertas WHERE usuario_id = ? AND lido = FALSE',
      [userId]
    );
    return rows[0].total;
  }

  static async create(data) {
    const [result] = await pool.execute(
      'INSERT INTO alertas (usuario_id, tipo, nivel, descricao) VALUES (?, ?, ?, ?)',
      [data.usuario_id, data.tipo, data.nivel || 'alto', data.descricao || null]
    );
    return this.findById(result.insertId);
  }

  static async markRead(id) {
    await pool.execute('UPDATE alertas SET lido = TRUE WHERE id = ?', [id]);
    return this.findById(id);
  }

  static async findByLevel(nivel, filters = {}) {
    let query = `SELECT al.*, u.nome as usuario_nome, u.setor as usuario_setor
                 FROM alertas al
                 JOIN usuarios u ON al.usuario_id = u.id
                 WHERE al.nivel = ?`;
    const params = [nivel];

    if (filters.lider_id) {
      query += ' AND u.lider_id = ?';
      params.push(filters.lider_id);
    }

    query += ' ORDER BY al.data DESC';

    if (filters.limit) {
      query += ' LIMIT ? OFFSET ?';
      params.push(filters.limit, filters.offset || 0);
    }

    const [rows] = await pool.execute(query, params);
    return rows;
  }

  static async findBySubordinates(liderId, filters = {}) {
    let query = `SELECT al.*, u.nome as usuario_nome, u.setor as usuario_setor
                 FROM alertas al
                 JOIN usuarios u ON al.usuario_id = u.id
                 WHERE u.lider_id = ?`;
    const params = [liderId];

    if (filters.lido !== undefined) {
      query += ' AND al.lido = ?';
      params.push(filters.lido);
    }

    query += ' ORDER BY al.data DESC';

    if (filters.limit) {
      query += ' LIMIT ? OFFSET ?';
      params.push(filters.limit, filters.offset || 0);
    }

    const [rows] = await pool.execute(query, params);
    return rows;
  }

  static async countUnreadBySubordinates(liderId) {
    const [rows] = await pool.execute(
      `SELECT COUNT(*) as total FROM alertas al
       JOIN usuarios u ON al.usuario_id = u.id
       WHERE u.lider_id = ? AND al.lido = FALSE`,
      [liderId]
    );
    return rows[0].total;
  }
}

module.exports = Alert;
