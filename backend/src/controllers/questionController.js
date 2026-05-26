const Question = require('../models/Question');
const { successResponse, errorResponse } = require('../utils/helpers');

async function listQuestions(req, res, next) {
  try {
    const questions = await Question.findAll();
    return successResponse(res, questions, 'Lista de perguntas');
  } catch (error) {
    next(error);
  }
}

async function listActiveQuestions(req, res, next) {
  try {
    const questions = await Question.findActive();
    return successResponse(res, questions, 'Perguntas ativas');
  } catch (error) {
    next(error);
  }
}

async function getQuestion(req, res, next) {
  try {
    const question = await Question.findById(req.params.id);
    if (!question) {
      return errorResponse(res, 'Pergunta nao encontrada', 404);
    }
    return successResponse(res, question, 'Detalhes da pergunta');
  } catch (error) {
    next(error);
  }
}

async function createQuestion(req, res, next) {
  try {
    const { texto, categoria, tipo, ativa, ordem } = req.body;
    const question = await Question.create({ texto, categoria, tipo, ativa, ordem });
    return successResponse(res, question, 'Pergunta criada com sucesso', 201);
  } catch (error) {
    next(error);
  }
}

async function updateQuestion(req, res, next) {
  try {
    const existing = await Question.findById(req.params.id);
    if (!existing) {
      return errorResponse(res, 'Pergunta nao encontrada', 404);
    }

    const question = await Question.update(req.params.id, req.body);
    return successResponse(res, question, 'Pergunta atualizada com sucesso');
  } catch (error) {
    next(error);
  }
}

async function deleteQuestion(req, res, next) {
  try {
    const existing = await Question.findById(req.params.id);
    if (!existing) {
      return errorResponse(res, 'Pergunta nao encontrada', 404);
    }

    await Question.delete(req.params.id);
    return successResponse(res, null, 'Pergunta removida com sucesso');
  } catch (error) {
    next(error);
  }
}

module.exports = { listQuestions, listActiveQuestions, getQuestion, createQuestion, updateQuestion, deleteQuestion };
