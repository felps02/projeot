function errorHandler(err, req, res, _next) {
  console.error('Error:', err.message);
  console.error('Stack:', err.stack);

  if (err.code === 'ER_DUP_ENTRY') {
    return res.status(409).json({
      success: false,
      data: null,
      message: 'Registro duplicado. Verifique os dados e tente novamente.'
    });
  }

  if (err.code === 'ER_NO_REFERENCED_ROW_2') {
    return res.status(400).json({
      success: false,
      data: null,
      message: 'Referencia invalida. Verifique os dados relacionados.'
    });
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

  return res.status(statusCode).json({
    success: false,
    data: null,
    message
  });
}

module.exports = errorHandler;
