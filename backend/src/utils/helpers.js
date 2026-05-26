function successResponse(res, data, message = 'Operacao realizada com sucesso', statusCode = 200) {
  return res.status(statusCode).json({
    success: true,
    data,
    message
  });
}

function errorResponse(res, message = 'Erro interno do servidor', statusCode = 500, errors = null) {
  const response = {
    success: false,
    data: null,
    message
  };
  if (errors) {
    response.errors = errors;
  }
  return res.status(statusCode).json(response);
}

function paginationParams(query) {
  const page = Math.max(1, parseInt(query.page, 10) || 1);
  const limit = Math.min(100, Math.max(1, parseInt(query.limit, 10) || 20));
  const offset = (page - 1) * limit;
  return { page, limit, offset };
}

function todayDateString() {
  const now = new Date();
  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, '0');
  const day = String(now.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

function daysAgoDateString(days) {
  const d = new Date();
  d.setDate(d.getDate() - days);
  const year = d.getFullYear();
  const month = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

module.exports = {
  successResponse,
  errorResponse,
  paginationParams,
  todayDateString,
  daysAgoDateString
};
