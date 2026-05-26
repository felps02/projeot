const jwt = require('jsonwebtoken');
const jwtConfig = require('../config/jwt');
const User = require('../models/User');
const { successResponse, errorResponse } = require('../utils/helpers');

async function login(req, res, next) {
  try {
    const { email, senha } = req.body;

    const user = await User.findByEmail(email);
    if (!user) {
      return errorResponse(res, 'Credenciais invalidas', 401);
    }

    if (user.status === 'inativo') {
      return errorResponse(res, 'Usuario inativo. Contate o administrador.', 403);
    }

    const isMatch = await User.comparePassword(senha, user.senha);
    if (!isMatch) {
      return errorResponse(res, 'Credenciais invalidas', 401);
    }

    const token = jwt.sign(
      { id: user.id, email: user.email, perfil: user.perfil },
      jwtConfig.secret,
      { expiresIn: jwtConfig.expiresIn }
    );

    const { senha: _, ...userData } = user;

    return successResponse(res, { token, usuario: userData }, 'Login realizado com sucesso');
  } catch (error) {
    next(error);
  }
}

async function register(req, res, next) {
  try {
    const { nome, email, senha, cargo, perfil, setor, lider_id } = req.body;

    const existingUser = await User.findByEmail(email);
    if (existingUser) {
      return errorResponse(res, 'Email ja cadastrado', 409);
    }

    const user = await User.create({ nome, email, senha, cargo, perfil, setor, lider_id });

    const token = jwt.sign(
      { id: user.id, email: user.email, perfil: user.perfil },
      jwtConfig.secret,
      { expiresIn: jwtConfig.expiresIn }
    );

    return successResponse(res, { token, usuario: user }, 'Registro realizado com sucesso', 201);
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

module.exports = { login, register, me };
