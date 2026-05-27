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
    `SELECT u.id
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
        descricao: `Sem check-in em ${dateStr}`
      });
      alerts.push(alert);
    }
  }

  return alerts;
}

// Notifica o lider via alerta agregado (sem identificar o funcionario).
// Para emergencias use notifyLeaderEmergency (usuario opta por se expor).
async function notifyLeader(userId, alertType, _description) {
  const [rows] = await pool.execute(
    'SELECT lider_id, setor, turno FROM usuarios WHERE id = ?',
    [userId]
  );
  if (!rows[0] || !rows[0].lider_id) return null;

  const { lider_id, setor, turno } = rows[0];
  const escopo = [setor && `setor ${setor}`, turno && `turno ${turno}`].filter(Boolean).join(', ') || 'sua equipe';

  return createAlert({
    usuario_id: lider_id,
    tipo: alertType,
    nivel: alertType === 'risco_alto' ? 'alto' : 'moderado',
    descricao: `[Anonimizado] Novo sinal em ${escopo}. Consulte o dashboard agregado.`
  });
}

async function notifyLeaderEmergency(userId, motivo) {
  const [rows] = await pool.execute(
    'SELECT u.lider_id, u.nome FROM usuarios u WHERE u.id = ?',
    [userId]
  );
  if (!rows[0] || !rows[0].lider_id) return null;

  return createAlert({
    usuario_id: rows[0].lider_id,
    tipo: 'emergencia',
    nivel: 'critico',
    descricao: `Emergencia registrada por ${rows[0].nome}: ${motivo}`
  });
}

module.exports = {
  createAlert,
  checkMissedCheckins,
  notifyLeader,
  notifyLeaderEmergency
};
