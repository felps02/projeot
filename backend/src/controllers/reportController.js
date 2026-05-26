const reportService = require('../services/reportService');
const { successResponse, errorResponse } = require('../utils/helpers');

async function getIndividualReport(req, res, next) {
  try {
    const userId = parseInt(req.params.userId, 10);
    const dateRange = {
      startDate: req.query.startDate,
      endDate: req.query.endDate
    };

    const report = await reportService.generateIndividualReport(userId, dateRange);
    if (!report) {
      return errorResponse(res, 'Usuario nao encontrado', 404);
    }

    return successResponse(res, report, 'Relatorio individual');
  } catch (error) {
    next(error);
  }
}

async function getTeamReport(req, res, next) {
  try {
    const leaderId = parseInt(req.params.liderId, 10);

    if (req.user.perfil === 'lider' && req.user.id !== leaderId) {
      return errorResponse(res, 'Acesso negado', 403);
    }

    const dateRange = {
      startDate: req.query.startDate,
      endDate: req.query.endDate
    };

    const report = await reportService.generateTeamReport(leaderId, dateRange);
    return successResponse(res, report, 'Relatorio da equipe');
  } catch (error) {
    next(error);
  }
}

async function getSectorReport(req, res, next) {
  try {
    const setor = req.params.setor;
    const dateRange = {
      startDate: req.query.startDate,
      endDate: req.query.endDate
    };

    const report = await reportService.generateSectorReport(setor, dateRange);
    return successResponse(res, report, 'Relatorio do setor');
  } catch (error) {
    next(error);
  }
}

async function exportPdf(req, res, next) {
  try {
    const { tipo, id, setor, startDate, endDate } = req.query;
    const dateRange = { startDate, endDate };
    let reportData;
    let reportType;

    if (tipo === 'individual') {
      reportData = await reportService.generateIndividualReport(parseInt(id, 10), dateRange);
      reportType = 'individual';
    } else if (tipo === 'equipe') {
      reportData = await reportService.generateTeamReport(parseInt(id, 10), dateRange);
      reportType = 'equipe';
    } else if (tipo === 'setor') {
      reportData = await reportService.generateSectorReport(setor, dateRange);
      reportType = 'setor';
    } else {
      return errorResponse(res, 'Tipo de relatorio invalido. Use: individual, equipe ou setor', 400);
    }

    if (!reportData) {
      return errorResponse(res, 'Dados nao encontrados para gerar o relatorio', 404);
    }

    const pdfBuffer = await reportService.generatePDF(reportData, reportType);

    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename=relatorio_${reportType}_${Date.now()}.pdf`);
    res.setHeader('Content-Length', pdfBuffer.length);
    return res.send(pdfBuffer);
  } catch (error) {
    next(error);
  }
}

async function exportExcel(req, res, next) {
  try {
    const { tipo, id, setor, startDate, endDate } = req.query;
    const dateRange = { startDate, endDate };
    let reportData;
    let reportType;

    if (tipo === 'individual') {
      reportData = await reportService.generateIndividualReport(parseInt(id, 10), dateRange);
      reportType = 'individual';
    } else if (tipo === 'equipe') {
      reportData = await reportService.generateTeamReport(parseInt(id, 10), dateRange);
      reportType = 'equipe';
    } else if (tipo === 'setor') {
      reportData = await reportService.generateSectorReport(setor, dateRange);
      reportType = 'setor';
    } else {
      return errorResponse(res, 'Tipo de relatorio invalido. Use: individual, equipe ou setor', 400);
    }

    if (!reportData) {
      return errorResponse(res, 'Dados nao encontrados para gerar o relatorio', 404);
    }

    const excelBuffer = await reportService.generateExcel(reportData, reportType);

    res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    res.setHeader('Content-Disposition', `attachment; filename=relatorio_${reportType}_${Date.now()}.xlsx`);
    res.setHeader('Content-Length', excelBuffer.length);
    return res.send(excelBuffer);
  } catch (error) {
    next(error);
  }
}

module.exports = { getIndividualReport, getTeamReport, getSectorReport, exportPdf, exportExcel };
