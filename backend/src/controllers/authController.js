const jwt = require('jsonwebtoken');
const jwtConfig = require('../config/jwt');
const User = require('../models/User');
const AuditLog = require('../models/AuditLog');
const { successResponse, errorResponse } = require('../utils/helpers');

async function register(req, res, next) {
  try {
    const { nome, email, senha, cargo, perfil, setor, turno, lider_id } = req.body;
    const existingUser = await User.findByEmail(email);
    if (existingUser) {
      return errorResponse(res, 'Email ja cadastrado', 409);
    }
    const newUser = await User.create({
      nome, email, senha, cargo, perfil, setor, turno, lider_id
    });
    const { senha: _, ...userData } = newUser;
    return successResponse(res, userData, 'Usuario registrado com sucesso');
  } catch (error) {
    next(error);
  }
}

async function login(req, res, next) {
  try {
    const { email, senha } = req.body;

    const user = await User.findByEmail(email);
    if (!user) {
      AuditLog.log(req, {
        acao: 'auth.login_failed',
        detalhes: `email=${email} motivo=usuario_nao_encontrado`
      });
      return errorResponse(res, 'Credenciais invalidas', 401);
    }

    if (user.status === 'inativo') {
      AuditLog.log(req, {
        acao: 'auth.login_failed',
        recurso: 'usuario',
        recurso_id: user.id,
        detalhes: 'usuario inativo'
      });
      return errorResponse(res, 'Usuario inativo. Contate o administrador.', 403);
    }

    const isMatch = await User.comparePassword(senha, user.senha);
    if (!isMatch) {
      AuditLog.log(req, {
        acao: 'auth.login_failed',
        recurso: 'usuario',
        recurso_id: user.id,
        detalhes: 'senha incorreta'
      });
      return errorResponse(res, 'Credenciais invalidas', 401);
    }

    const token = jwt.sign(
      { id: user.id, email: user.email, perfil: user.perfil },
      jwtConfig.secret,
      { expiresIn: jwtConfig.expiresIn }
    );

    const { senha: _, ...userData } = user;

    AuditLog.log(req, {
      acao: 'auth.login_success',
      recurso: 'usuario',
      recurso_id: user.id,
      detalhes: `perfil=${user.perfil}`
    });

    return successResponse(res, { token, usuario: userData }, 'Login realizado com sucesso');
  } catch (error) {
    next(error);
  }
}

async function me(req, res, next) {
  try {
    const user = await User.findById(req.user.id);
    if (!user) {
      return errorResponse(res, 'Usuario nao encontrado', 404);
    }
    return successResponse(res, user, 'Dados do usuario');
  } catch (error) {
    next(error);
  }
}

module.exports = { login, me, register };
