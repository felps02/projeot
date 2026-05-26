const pool = require('../config/database');

class Assessment {
  static async findById(id) {
    const [rows] = await pool.execute(
      `SELECT a.*, u.nome as usuario_nome, u.setor as usuario_setor
       FROM avaliacoes a
       JOIN usuarios u ON a.usuario_id = u.id
       WHERE a.id = ?`,
      [id]
    );
    return rows[0] || null;
  }

  static async findByUser(userId, filters = {}) {
    let query = `SELECT a.*, u.nome as usuario_nome
                 FROM avaliacoes a
                 JOIN usuarios u ON a.usuario_id = u.id
                 WHERE a.usuario_id = ?`;
    const params = [userId];

    if (filters.startDate) {
      query += ' AND a.data >= ?';
      params.push(filters.startDate);
    }
    if (filters.endDate) {
      query += ' AND a.data <= ?';
      params.push(filters.endDate);
    }

    query += ' ORDER BY a.data DESC';

    if (filters.limit) {
      query += ' LIMIT ? OFFSET ?';
      params.push(filters.limit, filters.offset || 0);
    }

    const [rows] = await pool.execute(query, params);
    return rows;
  }

  static async findByDate(userId, date) {
    const [rows] = await pool.execute(
      'SELECT * FROM avaliacoes WHERE usuario_id = ? AND data = ?',
      [userId, date]
    );
    return rows[0] || null;
  }

  static async create(data) {
    const [result] = await pool.execute(
      'INSERT INTO avaliacoes (usuario_id, data, score_risco, nivel_risco, completada) VALUES (?, ?, ?, ?, ?)',
      [data.usuario_id, data.data, data.score_risco || 0, data.nivel_risco || 'baixo', data.completada || false]
    );
    return this.findById(result.insertId);
  }

  static async complete(id, scoreRisco, nivelRisco) {
    await pool.execute(
      'UPDATE avaliacoes SET score_risco = ?, nivel_risco = ?, completada = TRUE WHERE id = ?',
      [scoreRisco, nivelRisco, id]
    );
    return this.findById(id);
  }

  static async getHistory(userId, limit = 30, offset = 0) {
    const [rows] = await pool.execute(
      `SELECT a.*, u.nome as usuario_nome
       FROM avaliacoes a
       JOIN usuarios u ON a.usuario_id = u.id
       WHERE a.usuario_id = ? AND a.completada = TRUE
       ORDER BY a.data DESC
       LIMIT ? OFFSET ?`,
      [userId, limit, offset]
    );
    return rows;
  }

  static async getDailyStats(date, filters = {}) {
    let query = `SELECT
                   COUNT(*) as total_avaliacoes,
                   AVG(a.score_risco) as media_risco,
                   SUM(CASE WHEN a.nivel_risco = 'baixo' THEN 1 ELSE 0 END) as baixo,
                   SUM(CASE WHEN a.nivel_risco = 'moderado' THEN 1 ELSE 0 END) as moderado,
                   SUM(CASE WHEN a.nivel_risco = 'alto' THEN 1 ELSE 0 END) as alto,
                   SUM(CASE WHEN a.nivel_risco = 'critico' THEN 1 ELSE 0 END) as critico
                 FROM avaliacoes a
                 JOIN usuarios u ON a.usuario_id = u.id
                 WHERE a.data = ? AND a.completada = TRUE`;
    const params = [date];

    if (filters.setor) {
      query += ' AND u.setor = ?';
      params.push(filters.setor);
    }
    if (filters.lider_id) {
      query += ' AND u.lider_id = ?';
      params.push(filters.lider_id);
    }

    const [rows] = await pool.execute(query, params);
    return rows[0];
  }

  static async getBySubordinates(liderId, filters = {}) {
    let query = `SELECT a.*, u.nome as usuario_nome, u.setor as usuario_setor
                 FROM avaliacoes a
                 JOIN usuarios u ON a.usuario_id = u.id
                 WHERE u.lider_id = ?`;
    const params = [liderId];

    if (filters.startDate) {
      query += ' AND a.data >= ?';
      params.push(filters.startDate);
    }
    if (filters.endDate) {
      query += ' AND a.data <= ?';
      params.push(filters.endDate);
    }

    query += ' ORDER BY a.data DESC';

    if (filters.limit) {
      query += ' LIMIT ? OFFSET ?';
      params.push(filters.limit, filters.offset || 0);
    }

    const [rows] = await pool.execute(query, params);
    return rows;
  }

  static async countByUser(userId) {
    const [rows] = await pool.execute(
      'SELECT COUNT(*) as total FROM avaliacoes WHERE usuario_id = ? AND completada = TRUE',
      [userId]
    );
    return rows[0].total;
  }
}

module.exports = Assessment;
