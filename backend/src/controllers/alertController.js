const Alert = require('../models/Alert');
const { successResponse, errorResponse, paginationParams } = require('../utils/helpers');
const { K_MIN, shouldSuppress, suppressedGroup } = require('../utils/privacy');

async function listAlerts(req, res, next) {
  try {
    const { page, limit, offset } = paginationParams(req.query);
    const filters = { limit, offset };

    if (req.query.tipo) filters.tipo = req.query.tipo;
    if (req.query.lido !== undefined) filters.lido = req.query.lido === 'true';

    if (req.user.perfil === 'lider') {
      return errorResponse(res,
        'Lideres acessam apenas dados agregados. Use GET /api/v1/alertas/agregado.',
        403
      );
    }

    const alerts = await Alert.findByUser(req.user.id, filters);

    return successResponse(res, {
      alertas: alerts,
      paginacao: { pagina: page, limite: limit }
    }, 'Lista de alertas');
  } catch (error) {
    next(error);
  }
}

async function getAggregated(req, res, next) {
  try {
    const dimensao = req.query.dimensao === 'turno' ? 'turno' : 'setor';
    const filters = {};
    if (req.query.lido !== undefined) filters.lido = req.query.lido === 'true';
    if (req.query.tipo) filters.tipo = req.query.tipo;
    if (req.query.nivel) filters.nivel = req.query.nivel;

    const rows = await Alert.aggregateByGroup(dimensao, filters);

    return successResponse(res, {
      dimensao,
      k_minimo: K_MIN,
      grupos: rows.map(r => shouldSuppress(r.pessoas_distintas)
        ? { grupo: r.grupo, nivel: r.nivel, tipo: r.tipo, ...suppressedGroup() }
        : {
            grupo: r.grupo,
            nivel: r.nivel,
            tipo: r.tipo,
            total_alertas: r.total,
            pessoas: r.pessoas_distintas
          }
      )
    }, 'Alertas agregados');
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

    if (alert.usuario_id !== req.user.id) {
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
    if (req.user.perfil === 'lider') {
      return errorResponse(res,
        'Lideres acessam apenas dados agregados. Use GET /api/v1/alertas/agregado.',
        403
      );
    }
    const total = await Alert.countUnread(req.user.id);
    return successResponse(res, { nao_lidos: total }, 'Contagem de alertas nao lidos');
  } catch (error) {
    next(error);
  }
}

module.exports = { listAlerts, markAsRead, countUnread, getAggregated };
