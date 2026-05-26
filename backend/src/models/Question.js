const pool = require('../config/database');

class Question {
  static async findAll() {
    const [rows] = await pool.execute('SELECT * FROM perguntas ORDER BY ordem ASC');
    return rows;
  }

  static async findActive() {
    const [rows] = await pool.execute('SELECT * FROM perguntas WHERE ativa = TRUE ORDER BY ordem ASC');
    return rows;
  }

  static async findById(id) {
    const [rows] = await pool.execute('SELECT * FROM perguntas WHERE id = ?', [id]);
    return rows[0] || null;
  }

  static async create(data) {
    const [result] = await pool.execute(
      'INSERT INTO perguntas (texto, categoria, tipo, ativa, ordem) VALUES (?, ?, ?, ?, ?)',
      [data.texto, data.categoria, data.tipo || 'likert', data.ativa !== undefined ? data.ativa : true, data.ordem || 0]
    );
    return this.findById(result.insertId);
  }

  static async update(id, data) {
    const fields = [];
    const params = [];

    if (data.texto !== undefined) { fields.push('texto = ?'); params.push(data.texto); }
    if (data.categoria !== undefined) { fields.push('categoria = ?'); params.push(data.categoria); }
    if (data.tipo !== undefined) { fields.push('tipo = ?'); params.push(data.tipo); }
    if (data.ativa !== undefined) { fields.push('ativa = ?'); params.push(data.ativa); }
    if (data.ordem !== undefined) { fields.push('ordem = ?'); params.push(data.ordem); }

    if (fields.length === 0) return this.findById(id);

    params.push(id);
    await pool.execute(`UPDATE perguntas SET ${fields.join(', ')} WHERE id = ?`, params);
    return this.findById(id);
  }

  static async toggleActive(id) {
    await pool.execute('UPDATE perguntas SET ativa = NOT ativa WHERE id = ?', [id]);
    return this.findById(id);
  }

  static async delete(id) {
    await pool.execute('DELETE FROM perguntas WHERE id = ?', [id]);
    return true;
  }
}

module.exports = Question;
