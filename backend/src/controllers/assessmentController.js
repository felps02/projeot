const Assessment = require('../models/Assessment');
const Answer = require('../models/Answer');
const riskEngine = require('../services/riskEngine');
const AuditLog = require('../models/AuditLog');
const { successResponse, errorResponse, paginationParams, todayDateString } = require('../utils/helpers');

async function createAssessment(req, res, next) {
  try {
    const userId = req.user.id;
    const today = todayDateString();

    const existing = await Assessment.findByDate(userId, today);
    if (existing && existing.completada) {
      return errorResponse(res, 'Avaliacao de hoje ja foi realizada', 409);
    }

    const { respostas } = req.body;

    const riskScore = riskEngine.calculateRiskScore(respostas);
    const riskLevel = riskEngine.classifyRisk(riskScore);

    let assessment;
    if (existing && !existing.completada) {
      assessment = await Assessment.complete(existing.id, riskScore, riskLevel);
    } else {
      assessment = await Assessment.create({
        usuario_id: userId,
        data: today,
        score_risco: riskScore,
        nivel_risco: riskLevel,
        completada: true
      });
    }

    const answers = await Answer.createBulk(assessment.id, respostas);

    await riskEngine.generateAlerts(userId, assessment);

    return successResponse(res, {
      avaliacao: assessment,
      respostas: answers,
      risco: { score: riskScore, nivel: riskLevel }
    }, 'Avaliacao registrada com sucesso', 201);
  } catch (error) {
    next(error);
  }
}

async function listAssessments(req, res, next) {
  try {
    const { page, limit, offset } = paginationParams(req.query);
    const filters = { limit, offset };

    if (req.query.startDate) filters.startDate = req.query.startDate;
    if (req.query.endDate) filters.endDate = req.query.endDate;

    if (req.user.perfil === 'lider') {
      return errorResponse(res,
        'Lideres nao acessam avaliacoes individuais. Use GET /api/v1/dashboard para dados agregados.',
        403
      );
    }

    let assessments;
    if (req.user.perfil === 'administrador' && req.query.usuario_id) {
      assessments = await Assessment.findByUser(parseInt(req.query.usuario_id, 10), filters);
      AuditLog.log(req, {
        acao: 'assessment.list_individual',
        recurso: 'usuario',
        recurso_id: parseInt(req.query.usuario_id, 10),
        detalhes: 'admin listou avaliacoes individuais'
      });
    } else {
      assessments = await Assessment.findByUser(req.user.id, filters);
    }

    return successResponse(res, {
      avaliacoes: assessments,
      paginacao: { pagina: page, limite: limit }
    }, 'Lista de avaliacoes');
  } catch (error) {
    next(error);
  }
}

async function getAssessment(req, res, next) {
  try {
    const assessment = await Assessment.findById(req.params.id);
    if (!assessment) {
      return errorResponse(res, 'Avaliacao nao encontrada', 404);
    }

    const isSelf = assessment.usuario_id === req.user.id;
    const isAdmin = req.user.perfil === 'administrador';

    if (!isSelf && !isAdmin) {
      return errorResponse(res, 'Acesso negado. Dados individuais sao restritos.', 403);
    }

    const answers = await Answer.findByAssessment(assessment.id);

    if (isAdmin && !isSelf) {
      AuditLog.log(req, {
        acao: 'assessment.view_individual',
        recurso: 'avaliacao',
        recurso_id: assessment.id,
        detalhes: `admin acessou avaliacao individual do usuario ${assessment.usuario_id}`
      });
    }

    return successResponse(res, {
      avaliacao: assessment,
      respostas: answers
    }, 'Detalhes da avaliacao');
  } catch (error) {
    next(error);
  }
}

async function getHistory(req, res, next) {
  try {
    const { page, limit, offset } = paginationParams(req.query);

    if (req.user.perfil === 'lider') {
      return errorResponse(res,
        'Lideres nao acessam historicos individuais. Use GET /api/v1/dashboard/tendencias.',
        403
      );
    }

    const userId = req.user.perfil === 'administrador' && req.query.usuario_id
      ? parseInt(req.query.usuario_id, 10)
      : req.user.id;

    if (req.user.perfil === 'administrador' && userId !== req.user.id) {
      AuditLog.log(req, {
        acao: 'assessment.view_history',
        recurso: 'usuario',
        recurso_id: userId,
        detalhes: 'admin acessou historico individual'
      });
    }

    const history = await Assessment.getHistory(userId, limit, offset);
    const total = await Assessment.countByUser(userId);

    return successResponse(res, {
      historico: history,
      paginacao: { pagina: page, limite: limit, total }
    }, 'Historico de avaliacoes');
  } catch (error) {
    next(error);
  }
}

async function checkToday(req, res, next) {
  try {
    const today = todayDateString();
    const assessment = await Assessment.findByDate(req.user.id, today);

    const done = assessment !== null && (assessment.completada === 1 || assessment.completada === true);

    return successResponse(res, {
      realizada: done,
      avaliacao: done ? assessment : null
    }, done ? 'Avaliacao de hoje ja foi realizada' : 'Avaliacao de hoje pendente');
  } catch (error) {
    next(error);
  }
}

module.exports = { createAssessment, listAssessments, getAssessment, getHistory, checkToday };
