const pool = require('../config/database');

class Answer {
  static async findByAssessment(avaliacaoId) {
    const [rows] = await pool.execute(
      `SELECT r.*, p.texto as pergunta_texto, p.categoria, p.tipo
       FROM respostas r
       JOIN perguntas p ON r.pergunta_id = p.id
       WHERE r.avaliacao_id = ?
       ORDER BY p.ordem ASC`,
      [avaliacaoId]
    );
    return rows;
  }

  static async create(data) {
    const [result] = await pool.execute(
      'INSERT INTO respostas (avaliacao_id, pergunta_id, valor) VALUES (?, ?, ?)',
      [data.avaliacao_id, data.pergunta_id, data.valor]
    );
    return { id: result.insertId, ...data };
  }

  static async createBulk(avaliacaoId, answers) {
    if (!answers || answers.length === 0) return [];

    const placeholders = answers.map(() => '(?, ?, ?)').join(', ');
    const params = [];
    for (const answer of answers) {
      params.push(avaliacaoId, answer.pergunta_id, answer.valor);
    }

    await pool.execute(
      `INSERT INTO respostas (avaliacao_id, pergunta_id, valor) VALUES ${placeholders}`,
      params
    );

    return this.findByAssessment(avaliacaoId);
  }
}

module.exports = Answer;
