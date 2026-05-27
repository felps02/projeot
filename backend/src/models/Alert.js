const pool = require('../config/database');

class Alert {
  static async findById(id) {
    const [rows] = await pool.execute(
      `SELECT al.*, u.setor as usuario_setor, u.turno as usuario_turno
       FROM alertas al
       JOIN usuarios u ON al.usuario_id = u.id
       WHERE al.id = ?`,
      [id]
    );
    return rows[0] || null;
  }

  static async findByUser(userId, filters = {}) {
    let query = `SELECT al.* FROM alertas al WHERE al.usuario_id = ?`;
    const params = [userId];

    if (filters.tipo) { query += ' AND al.tipo = ?'; params.push(filters.tipo); }
    if (filters.lido !== undefined) { query += ' AND al.lido = ?'; params.push(filters.lido); }

    query += ' ORDER BY al.data DESC';

    if (filters.limit) {
      query += ' LIMIT ? OFFSET ?';
      params.push(filters.limit, filters.offset || 0);
    }

    const [rows] = await pool.execute(query, params);
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

  static async aggregateByGroup(dimensao, filters = {}) {
    const groupCol = dimensao === 'turno' ? 'u.turno' : 'u.setor';
    const fallback = dimensao === 'turno' ? 'Sem Turno' : 'Sem Setor';

    let query = `SELECT
                   COALESCE(${groupCol}, ?) as grupo,
                   al.nivel,
                   al.tipo,
                   COUNT(*) as total,
                   COUNT(DISTINCT al.usuario_id) as pessoas_distintas
                 FROM alertas al
                 JOIN usuarios u ON al.usuario_id = u.id
                 WHERE 1=1`;
    const params = [fallback];

    if (filters.lido !== undefined) { query += ' AND al.lido = ?'; params.push(filters.lido); }
    if (filters.tipo) { query += ' AND al.tipo = ?'; params.push(filters.tipo); }
    if (filters.nivel) { query += ' AND al.nivel = ?'; params.push(filters.nivel); }

    query += ` GROUP BY ${groupCol}, al.nivel, al.tipo ORDER BY grupo, al.nivel`;

    const [rows] = await pool.execute(query, params);
    return rows;
  }

  static async countAllUnread(filters = {}) {
    let query = `SELECT COUNT(*) as total
                 FROM alertas al
                 JOIN usuarios u ON al.usuario_id = u.id
                 WHERE al.lido = FALSE`;
    const params = [];
    if (filters.setor) { query += ' AND u.setor = ?'; params.push(filters.setor); }
    if (filters.turno) { query += ' AND u.turno = ?'; params.push(filters.turno); }
    const [rows] = await pool.execute(query, params);
    return rows[0].total;
  }
}

module.exports = Alert;
