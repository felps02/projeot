const { errorResponse } = require('../utils/helpers');

function authorize(allowedRoles) {
  return (req, res, next) => {
    if (!req.user) {
      return errorResponse(res, 'Autenticacao necessaria', 401);
    }

    if (!allowedRoles.includes(req.user.perfil)) {
      return errorResponse(res, 'Acesso negado. Permissao insuficiente.', 403);
    }

    next();
  };
}

module.exports = authorize;
