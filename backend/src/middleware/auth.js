const jwt = require('jsonwebtoken');
const jwtConfig = require('../config/jwt');
const User = require('../models/User');
const { errorResponse } = require('../utils/helpers');

async function authMiddleware(req, res, next) {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return errorResponse(res, 'Token de autenticacao nao fornecido', 401);
    }

    const token = authHeader.split(' ')[1];

    let decoded;
    try {
      decoded = jwt.verify(token, jwtConfig.secret);
    } catch (err) {
      if (err.name === 'TokenExpiredError') {
        return errorResponse(res, 'Token expirado', 401);
      }
      return errorResponse(res, 'Token invalido', 401);
    }

    const user = await User.findById(decoded.id);

    if (!user) {
      return errorResponse(res, 'Usuario nao encontrado', 401);
    }

    if (user.status === 'inativo') {
      return errorResponse(res, 'Usuario inativo', 403);
    }

    req.user = user;
    next();
  } catch (error) {
    return errorResponse(res, 'Erro na autenticacao', 500);
  }
}

module.exports = authMiddleware;
