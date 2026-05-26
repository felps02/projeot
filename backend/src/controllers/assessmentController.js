const Assessment = require('../models/Assessment');
const Answer = require('../models/Answer');
const riskEngine = require('../services/riskEngine');
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

    let assessments;
    if (req.user.perfil === 'funcionario') {
      assessments = await Assessment.findByUser(req.user.id, filters);
    } else if (req.user.perfil === 'lider') {
      assessments = await Assessment.getBySubordinates(req.user.id, filters);
    } else {
      assessments = await Assessment.findByUser(req.query.usuario_id || req.user.id, filters);
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

    if (req.user.perfil === 'funcionario' && assessment.usuario_id !== req.user.id) {
      return errorResponse(res, 'Acesso negado', 403);
    }

    const answers = await Answer.findByAssessment(assessment.id);

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
    const userId = req.user.perfil === 'funcionario' ? req.user.id : (req.query.usuario_id || req.user.id);

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

    const done = assessment !== null && assessment.completada === 1;

    return successResponse(res, {
      realizada: done,
      avaliacao: done ? assessment : null
    }, done ? 'Avaliacao de hoje ja foi realizada' : 'Avaliacao de hoje pendente');
  } catch (error) {
    next(error);
  }
}

module.exports = { createAssessment, listAssessments, getAssessment, getHistory, checkToday };
