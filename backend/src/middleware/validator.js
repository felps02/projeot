const { body, param, validationResult } = require('express-validator');
const { errorResponse } = require('../utils/helpers');

function handleValidation(req, res, next) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    const messages = errors.array().map(e => e.msg);
    return errorResponse(res, messages.join('; '), 422, errors.array());
  }
  next();
}

const loginValidation = [
  body('email')
    .isEmail().withMessage('Email invalido')
    .normalizeEmail(),
  body('senha')
    .notEmpty().withMessage('Senha e obrigatoria')
    .isLength({ min: 6 }).withMessage('Senha deve ter no minimo 6 caracteres'),
  handleValidation
];

const createUserValidation = [
  body('nome')
    .notEmpty().withMessage('Nome e obrigatorio')
    .isLength({ min: 2, max: 100 }).withMessage('Nome deve ter entre 2 e 100 caracteres')
    .trim(),
  body('email')
    .isEmail().withMessage('Email invalido')
    .normalizeEmail(),
  body('senha')
    .notEmpty().withMessage('Senha e obrigatoria')
    .isLength({ min: 6 }).withMessage('Senha deve ter no minimo 6 caracteres'),
  body('cargo')
    .optional()
    .isLength({ max: 100 }).withMessage('Cargo deve ter no maximo 100 caracteres')
    .trim(),
  body('perfil')
    .optional()
    .isIn(['administrador', 'lider', 'funcionario']).withMessage('Perfil invalido'),
  body('setor')
    .optional()
    .isLength({ max: 100 }).withMessage('Setor deve ter no maximo 100 caracteres')
    .trim(),
  body('turno')
    .optional({ nullable: true })
    .isIn(['manha', 'tarde', 'noite', 'integral']).withMessage('Turno invalido'),
  body('lider_id')
    .optional({ nullable: true })
    .isInt({ min: 1 }).withMessage('ID do lider invalido'),
  handleValidation
];

const assessmentValidation = [
  body('respostas')
    .isArray({ min: 1 }).withMessage('Respostas sao obrigatorias e devem ser uma lista'),
  body('respostas.*.pergunta_id')
    .isInt({ min: 1 }).withMessage('ID da pergunta invalido'),
  body('respostas.*.valor')
    .isInt({ min: 1, max: 5 }).withMessage('Valor da resposta deve ser entre 1 e 5'),
  handleValidation
];

const questionValidation = [
  body('texto')
    .notEmpty().withMessage('Texto da pergunta e obrigatorio')
    .trim(),
  body('categoria')
    .notEmpty().withMessage('Categoria e obrigatoria')
    .isIn(['estresse', 'burnout', 'ansiedade', 'sobrecarga', 'motivacao', 'assedio', 'exaustao', 'ambiente'])
    .withMessage('Categoria invalida'),
  body('tipo')
    .optional()
    .isIn(['likert', 'emoji', 'selecao']).withMessage('Tipo invalido'),
  body('ativa')
    .optional()
    .isBoolean().withMessage('Campo ativa deve ser booleano'),
  body('ordem')
    .optional()
    .isInt({ min: 0 }).withMessage('Ordem deve ser um numero inteiro positivo'),
  handleValidation
];

const emergencyValidation = [
  body('motivo')
    .notEmpty().withMessage('Motivo e obrigatorio')
    .isLength({ max: 255 }).withMessage('Motivo deve ter no maximo 255 caracteres')
    .trim(),
  body('descricao')
    .optional()
    .trim(),
  body('prioridade')
    .optional()
    .isIn(['alta', 'critica']).withMessage('Prioridade invalida'),
  handleValidation
];

const updateUserValidation = [
  body('nome')
    .optional()
    .isLength({ min: 2, max: 100 }).withMessage('Nome deve ter entre 2 e 100 caracteres')
    .trim(),
  body('email')
    .optional()
    .isEmail().withMessage('Email invalido')
    .normalizeEmail(),
  body('senha')
    .optional()
    .isLength({ min: 6 }).withMessage('Senha deve ter no minimo 6 caracteres'),
  body('cargo')
    .optional({ nullable: true })
    .isLength({ max: 100 }).withMessage('Cargo deve ter no maximo 100 caracteres')
    .trim(),
  body('perfil')
    .optional()
    .isIn(['administrador', 'lider', 'funcionario']).withMessage('Perfil invalido'),
  body('setor')
    .optional({ nullable: true })
    .isLength({ max: 100 }).withMessage('Setor deve ter no maximo 100 caracteres')
    .trim(),
  body('turno')
    .optional({ nullable: true })
    .isIn(['manha', 'tarde', 'noite', 'integral']).withMessage('Turno invalido'),
  body('lider_id')
    .optional({ nullable: true })
    .isInt({ min: 1 }).withMessage('ID do lider invalido'),
  body('status')
    .optional()
    .isIn(['ativo', 'inativo']).withMessage('Status invalido'),
  handleValidation
];

const idParamValidation = [
  param('id')
    .isInt({ min: 1 }).withMessage('ID invalido'),
  handleValidation
];

const emergencyStatusValidation = [
  param('id')
    .isInt({ min: 1 }).withMessage('ID invalido'),
  body('status')
    .notEmpty().withMessage('Status e obrigatorio')
    .isIn(['aberta', 'em_atendimento', 'resolvida']).withMessage('Status invalido'),
  handleValidation
];

module.exports = {
  loginValidation,
  createUserValidation,
  assessmentValidation,
  questionValidation,
  emergencyValidation,
  updateUserValidation,
  idParamValidation,
  emergencyStatusValidation,
  handleValidation
};
