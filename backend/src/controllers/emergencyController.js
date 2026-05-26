const Emergency = require('../models/Emergency');
const alertService = require('../services/alertService');
const { successResponse, errorResponse } = require('../utils/helpers');

async function createEmergency(req, res, next) {
  try {
    const { motivo, descricao, prioridade } = req.body;

    const emergency = await Emergency.create({
      usuario_id: req.user.id,
      motivo,
      descricao,
      prioridade
    });

    await alertService.createAlert({
      usuario_id: req.user.id,
      tipo: 'emergencia',
      nivel: 'critico',
      descricao: `Emergencia registrada: ${motivo}`
    });

    await alertService.notifyLeader(
      req.user.id,
      'emergencia',
      `Emergencia registrada por ${req.user.nome}: ${motivo}`
    );

    return successResponse(res, emergency, 'Emergencia registrada com sucesso', 201);
  } catch (error) {
    next(error);
  }
}

async function listEmergencies(req, res, next) {
  try {
    const filters = {};

    if (req.query.status) filters.status = req.query.status;
    if (req.query.prioridade) filters.prioridade = req.query.prioridade;

    if (req.user.perfil === 'lider') {
      filters.lider_id = req.user.id;
    }

    const emergencies = await Emergency.findAll(filters);
    return successResponse(res, emergencies, 'Lista de emergencias');
  } catch (error) {
    next(error);
  }
}

async function updateEmergencyStatus(req, res, next) {
  try {
    const emergency = await Emergency.findById(req.params.id);
    if (!emergency) {
      return errorResponse(res, 'Emergencia nao encontrada', 404);
    }

    if (req.user.perfil === 'lider' && emergency.lider_id !== req.user.id) {
      return errorResponse(res, 'Acesso negado', 403);
    }

    const updated = await Emergency.updateStatus(req.params.id, req.body.status);
    return successResponse(res, updated, 'Status da emergencia atualizado');
  } catch (error) {
    next(error);
  }
}

async function getOpenEmergencies(req, res, next) {
  try {
    const filters = {};
    if (req.user.perfil === 'lider') {
      filters.lider_id = req.user.id;
    }

    const emergencies = await Emergency.findOpen(filters);
    return successResponse(res, emergencies, 'Emergencias abertas');
  } catch (error) {
    next(error);
  }
}

module.exports = { createEmergency, listEmergencies, updateEmergencyStatus, getOpenEmergencies };
