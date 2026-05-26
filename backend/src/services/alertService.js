const pool = require('../config/database');
const Alert = require('../models/Alert');

async function createAlert(data) {
  return Alert.create(data);
}

async function checkMissedCheckins() {
  const today = new Date();
  const year = today.getFullYear();
  const month = String(today.getMonth() + 1).padStart(2, '0');
  const day = String(today.getDate()).padStart(2, '0');
  const dateStr = `${year}-${month}-${day}`;

  const dayOfWeek = today.getDay();
  if (dayOfWeek === 0 || dayOfWeek === 6) return [];

  const [usersWithoutCheckin] = await pool.execute(
    `SELECT u.id, u.nome, u.lider_id
     FROM usuarios u
     WHERE u.status = 'ativo'
       AND u.perfil = 'funcionario'
       AND u.id NOT IN (
         SELECT a.usuario_id FROM avaliacoes a WHERE a.data = ?
       )`,
    [dateStr]
  );

  const alerts = [];
  for (const user of usersWithoutCheckin) {
    const [existing] = await pool.execute(
      `SELECT id FROM alertas
       WHERE usuario_id = ? AND tipo = 'sem_checkin' AND DATE(data) = ?`,
      [user.id, dateStr]
    );

    if (existing.length === 0) {
      const alert = await createAlert({
        usuario_id: user.id,
        tipo: 'sem_checkin',
        nivel: 'baixo',
        descricao: `${user.nome} nao realizou check-in em ${dateStr}`
      });
      alerts.push(alert);
    }
  }

  return alerts;
}

async function notifyLeader(userId, alertType, description) {
  const [rows] = await pool.execute(
    'SELECT lider_id FROM usuarios WHERE id = ?',
    [userId]
  );

  if (!rows[0] || !rows[0].lider_id) return null;

  const leaderId = rows[0].lider_id;

  const [userRows] = await pool.execute(
    'SELECT nome FROM usuarios WHERE id = ?',
    [userId]
  );
  const userName = userRows[0] ? userRows[0].nome : 'Funcionario';

  return createAlert({
    usuario_id: leaderId,
    tipo: alertType,
    nivel: alertType === 'risco_alto' ? 'alto' : 'moderado',
    descricao: `[Subordinado: ${userName}] ${description}`
  });
}

module.exports = {
  createAlert,
  checkMissedCheckins,
  notifyLeader
};
