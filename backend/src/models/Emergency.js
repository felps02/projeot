const pool = require('../config/database');

class Emergency {
  static async findById(id) {
    const [rows] = await pool.execute(
      `SELECT e.*, u.nome as usuario_nome, u.setor as usuario_setor, u.lider_id
       FROM emergencias e
       JOIN usuarios u ON e.usuario_id = u.id
       WHERE e.id = ?`,
      [id]
    );
    return rows[0] || null;
  }

  static async findByUser(userId, filters = {}) {
    let query = 'SELECT * FROM emergencias WHERE usuario_id = ?';
    const params = [userId];

    if (filters.status) {
      query += ' AND status = ?';
      params.push(filters.status);
    }

    query += ' ORDER BY data DESC';

    if (filters.limit) {
      query += ' LIMIT ? OFFSET ?';
      params.push(filters.limit, filters.offset || 0);
    }

    const [rows] = await pool.execute(query, params);
    return rows;
  }

  static async findOpen(filters = {}) {
    let query = `SELECT e.*, u.nome as usuario_nome, u.setor as usuario_setor
                 FROM emergencias e
                 JOIN usuarios u ON e.usuario_id = u.id
                 WHERE e.status != 'resolvida'`;
    const params = [];

    if (filters.lider_id) {
      query += ' AND u.lider_id = ?';
      params.push(filters.lider_id);
    }

    query += ' ORDER BY FIELD(e.prioridade, "critica", "alta"), e.data DESC';

    const [rows] = await pool.execute(query, params);
    return rows;
  }

  static async create(data) {
    const [result] = await pool.execute(
      'INSERT INTO emergencias (usuario_id, motivo, descricao, prioridade) VALUES (?, ?, ?, ?)',
      [data.usuario_id, data.motivo, data.descricao || null, data.prioridade || 'critica']
    );
    return this.findById(result.insertId);
  }

  static async updateStatus(id, status) {
    await pool.execute(
      'UPDATE emergencias SET status = ? WHERE id = ?',
      [status, id]
    );
    return this.findById(id);
  }

  static async findAll(filters = {}) {
    let query = `SELECT e.*, u.nome as usuario_nome, u.setor as usuario_setor
                 FROM emergencias e
                 JOIN usuarios u ON e.usuario_id = u.id
                 WHERE 1=1`;
    const params = [];

    if (filters.status) {
      query += ' AND e.status = ?';
      params.push(filters.status);
    }
    if (filters.lider_id) {
      query += ' AND u.lider_id = ?';
      params.push(filters.lider_id);
    }
    if (filters.prioridade) {
      query += ' AND e.prioridade = ?';
      params.push(filters.prioridade);
    }

    query += ' ORDER BY e.data DESC';

    if (filters.limit) {
      query += ' LIMIT ? OFFSET ?';
      params.push(filters.limit, filters.offset || 0);
    }

    const [rows] = await pool.execute(query, params);
    return rows;
  }
}

module.exports = Emergency;
