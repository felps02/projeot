const logger = require('../utils/logger');

const DB_ERROR_MAP = {
  ER_DUP_ENTRY: { status: 409, message: 'Registro duplicado. Verifique os dados e tente novamente.' },
  ER_NO_REFERENCED_ROW_2: { status: 400, message: 'Referencia invalida. Verifique os dados relacionados.' },
  ER_BAD_DB_ERROR: { status: 503, message: 'Banco de dados nao inicializado. Reinicie o servidor.' },
  ER_ACCESS_DENIED_ERROR: { status: 503, message: 'Falha de autenticacao no banco de dados. Verifique as credenciais.' },
  ER_NO_SUCH_TABLE: { status: 503, message: 'Tabela ausente. O banco precisa ser inicializado.' },
  ECONNREFUSED: { status: 503, message: 'Banco de dados indisponivel. Verifique se o MySQL esta rodando.' },
  PROTOCOL_CONNECTION_LOST: { status: 503, message: 'Conexao com o banco foi perdida. Tente novamente em instantes.' },
  ETIMEDOUT: { status: 503, message: 'Tempo esgotado ao acessar o banco de dados.' }
};

function errorHandler(err, req, res, _next) {
  const isProd = process.env.NODE_ENV === 'production';

  logger.error('Erro na requisicao', {
    method: req.method,
    path: req.originalUrl,
    code: err.code,
    message: err.message,
    stack: isProd ? undefined : err.stack
  });

  const mapped = err.code && DB_ERROR_MAP[err.code];
  if (mapped) {
    const payload = {
      success: false,
      data: null,
      message: mapped.message
    };
    if (!isProd) payload.debug = { code: err.code, original: err.message };
    return res.status(mapped.status).json(payload);
  }

  if (err.type === 'entity.parse.failed') {
    return res.status(400).json({
      success: false,
      data: null,
      message: 'JSON invalido no corpo da requisicao.'
    });
  }

  const statusCode = err.statusCode || 500;
  const message = err.statusCode ? err.message : 'Erro interno do servidor';

  const payload = { success: false, data: null, message };
  if (!isProd && statusCode === 500) {
    payload.debug = { message: err.message, code: err.code };
  }

  return res.status(statusCode).json(payload);
}

module.exports = errorHandler;
