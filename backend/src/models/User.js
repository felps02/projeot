const pool = require('../config/database');
const bcrypt = require('bcryptjs');

const PUBLIC_COLUMNS = 'id, nome, email, cargo, perfil, setor, turno, lider_id, status, created_at, updated_at';

class User {
  static async findById(id) {
    const [rows] = await pool.execute(
      `SELECT ${PUBLIC_COLUMNS} FROM usuarios WHERE id = ?`,
      [id]
    );
    return rows[0] || null;
  }

  static async findByEmail(email) {
    const [rows] = await pool.execute(
      'SELECT * FROM usuarios WHERE email = ?',
      [email]
    );
    return rows[0] || null;
  }

  static async findAll(filters = {}) {
    let query = `SELECT ${PUBLIC_COLUMNS} FROM usuarios WHERE 1=1`;
    const params = [];

    if (filters.status) { query += ' AND status = ?'; params.push(filters.status); }
    if (filters.perfil) { query += ' AND perfil = ?'; params.push(filters.perfil); }
    if (filters.setor) { query += ' AND setor = ?'; params.push(filters.setor); }
    if (filters.turno) { query += ' AND turno = ?'; params.push(filters.turno); }
    if (filters.lider_id) { query += ' AND lider_id = ?'; params.push(filters.lider_id); }

    query += ' ORDER BY nome ASC';

    if (filters.limit) {
      query += ' LIMIT ? OFFSET ?';
      params.push(filters.limit, filters.offset || 0);
    }

    const [rows] = await pool.execute(query, params);
    return rows;
  }

  static async create(data) {
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(data.senha, salt);

    const [result] = await pool.execute(
      `INSERT INTO usuarios (nome, email, senha, cargo, perfil, setor, turno, lider_id)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        data.nome,
        data.email,
        hashedPassword,
        data.cargo || null,
        data.perfil || 'funcionario',
        data.setor || null,
        data.turno || null,
        data.lider_id || null
      ]
    );

    return this.findById(result.insertId);
  }

  static async update(id, data) {
    const fields = [];
    const params = [];

    if (data.nome !== undefined) { fields.push('nome = ?'); params.push(data.nome); }
    if (data.email !== undefined) { fields.push('email = ?'); params.push(data.email); }
    if (data.cargo !== undefined) { fields.push('cargo = ?'); params.push(data.cargo); }
    if (data.perfil !== undefined) { fields.push('perfil = ?'); params.push(data.perfil); }
    if (data.setor !== undefined) { fields.push('setor = ?'); params.push(data.setor); }
    if (data.turno !== undefined) { fields.push('turno = ?'); params.push(data.turno); }
    if (data.lider_id !== undefined) { fields.push('lider_id = ?'); params.push(data.lider_id); }
    if (data.status !== undefined) { fields.push('status = ?'); params.push(data.status); }
    if (data.senha !== undefined) {
      const salt = await bcrypt.genSalt(10);
      const hashed = await bcrypt.hash(data.senha, salt);
      fields.push('senha = ?');
      params.push(hashed);
    }

    if (fields.length === 0) return this.findById(id);

    params.push(id);
    await pool.execute(`UPDATE usuarios SET ${fields.join(', ')} WHERE id = ?`, params);
    return this.findById(id);
  }

  static async delete(id) {
    await pool.execute('UPDATE usuarios SET status = ? WHERE id = ?', ['inativo', id]);
    return this.findById(id);
  }

  static async findByLider(liderId) {
    const [rows] = await pool.execute(
      `SELECT ${PUBLIC_COLUMNS} FROM usuarios WHERE lider_id = ? AND status = ?`,
      [liderId, 'ativo']
    );
    return rows;
  }

  static async findSubordinates(liderId) {
    const [rows] = await pool.execute(
      `SELECT ${PUBLIC_COLUMNS} FROM usuarios WHERE lider_id = ? ORDER BY nome ASC`,
      [liderId]
    );
    return rows;
  }

  static async isValidLeader(id) {
    const [rows] = await pool.execute(
      "SELECT id FROM usuarios WHERE id = ? AND perfil = 'lider' AND status = 'ativo'",
      [id]
    );
    return rows.length > 0;
  }

  static async countByPerfil(perfil) {
    const [rows] = await pool.execute(
      'SELECT COUNT(*) as total FROM usuarios WHERE perfil = ? AND status = ?',
      [perfil, 'ativo']
    );
    return rows[0].total;
  }

  static async comparePassword(plainPassword, hashedPassword) {
    return bcrypt.compare(plainPassword, hashedPassword);
  }

  static async countByFilters(filters = {}) {
    let query = 'SELECT COUNT(*) as total FROM usuarios WHERE 1=1';
    const params = [];

    if (filters.status) { query += ' AND status = ?'; params.push(filters.status); }
    if (filters.perfil) { query += ' AND perfil = ?'; params.push(filters.perfil); }
    if (filters.setor) { query += ' AND setor = ?'; params.push(filters.setor); }
    if (filters.turno) { query += ' AND turno = ?'; params.push(filters.turno); }
    if (filters.lider_id) { query += ' AND lider_id = ?'; params.push(filters.lider_id); }

    const [rows] = await pool.execute(query, params);
    return rows[0].total;
  }
}

module.exports = User;
