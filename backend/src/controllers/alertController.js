const Alert = require('../models/Alert');
const { successResponse, errorResponse, paginationParams } = require('../utils/helpers');

async function listAlerts(req, res, next) {
  try {
    const { page, limit, offset } = paginationParams(req.query);
    const filters = { limit, offset };

    if (req.query.tipo) filters.tipo = req.query.tipo;
    if (req.query.lido !== undefined) filters.lido = req.query.lido === 'true';

    let alerts;
    if (req.user.perfil === 'funcionario') {
      alerts = await Alert.findByUser(req.user.id, filters);
    } else if (req.user.perfil === 'lider') {
      const ownAlerts = await Alert.findByUser(req.user.id, filters);
      const subAlerts = await Alert.findBySubordinates(req.user.id, filters);
      alerts = [...ownAlerts, ...subAlerts].sort((a, b) => new Date(b.data) - new Date(a.data));
      if (limit) alerts = alerts.slice(0, limit);
    } else {
      alerts = await Alert.findByUser(req.user.id, filters);
    }

    return successResponse(res, {
      alertas: alerts,
      paginacao: { pagina: page, limite: limit }
    }, 'Lista de alertas');
  } catch (error) {
    next(error);
  }
}

async function markAsRead(req, res, next) {
  try {
    const alert = await Alert.findById(req.params.id);
    if (!alert) {
      return errorResponse(res, 'Alerta nao encontrado', 404);
    }

    if (alert.usuario_id !== req.user.id && req.user.perfil === 'funcionario') {
      return errorResponse(res, 'Acesso negado', 403);
    }

    const updated = await Alert.markRead(req.params.id);
    return successResponse(res, updated, 'Alerta marcado como lido');
  } catch (error) {
    next(error);
  }
}

async function countUnread(req, res, next) {
  try {
    let total;
    if (req.user.perfil === 'lider') {
      const own = await Alert.countUnread(req.user.id);
      const sub = await Alert.countUnreadBySubordinates(req.user.id);
      total = own + sub;
    } else {
      total = await Alert.countUnread(req.user.id);
    }

    return successResponse(res, { nao_lidos: total }, 'Contagem de alertas nao lidos');
  } catch (error) {
    next(error);
  }
}

module.exports = { listAlerts, markAsRead, countUnread };
