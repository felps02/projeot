const pool = require('../config/database');
const PDFDocument = require('pdfkit');
const ExcelJS = require('exceljs');
const { daysAgoDateString, todayDateString } = require('../utils/helpers');

async function generateIndividualReport(userId, dateRange = {}) {
  const startDate = dateRange.startDate || daysAgoDateString(30);
  const endDate = dateRange.endDate || todayDateString();

  const [userRows] = await pool.execute(
    'SELECT id, nome, email, cargo, setor FROM usuarios WHERE id = ?',
    [userId]
  );
  if (userRows.length === 0) return null;
  const user = userRows[0];

  const [assessments] = await pool.execute(
    `SELECT data, score_risco, nivel_risco
     FROM avaliacoes
     WHERE usuario_id = ? AND data BETWEEN ? AND ? AND completada = TRUE
     ORDER BY data ASC`,
    [userId, startDate, endDate]
  );

  const [categoryAvgs] = await pool.execute(
    `SELECT p.categoria, AVG(r.valor) as media
     FROM respostas r
     JOIN perguntas p ON r.pergunta_id = p.id
     JOIN avaliacoes a ON r.avaliacao_id = a.id
     WHERE a.usuario_id = ? AND a.data BETWEEN ? AND ? AND a.completada = TRUE
     GROUP BY p.categoria`,
    [userId, startDate, endDate]
  );

  const [alertCount] = await pool.execute(
    `SELECT tipo, COUNT(*) as total
     FROM alertas
     WHERE usuario_id = ? AND DATE(data) BETWEEN ? AND ?
     GROUP BY tipo`,
    [userId, startDate, endDate]
  );

  const avgScore = assessments.length > 0
    ? assessments.reduce((s, a) => s + parseFloat(a.score_risco), 0) / assessments.length
    : 0;

  return {
    usuario: user,
    periodo: { inicio: startDate, fim: endDate },
    resumo: {
      total_avaliacoes: assessments.length,
      media_score: Math.round(avgScore * 100) / 100,
      score_mais_recente: assessments.length > 0 ? parseFloat(assessments[assessments.length - 1].score_risco) : null
    },
    evolucao: assessments.map(a => ({
      data: a.data,
      score: parseFloat(a.score_risco),
      nivel: a.nivel_risco
    })),
    categorias: categoryAvgs.map(c => ({
      categoria: c.categoria,
      media: Math.round(parseFloat(c.media) * 100) / 100
    })),
    alertas: alertCount
  };
}

async function generateTeamReport(leaderId, dateRange = {}) {
  const startDate = dateRange.startDate || daysAgoDateString(30);
  const endDate = dateRange.endDate || todayDateString();

  const [leader] = await pool.execute(
    'SELECT id, nome, setor FROM usuarios WHERE id = ?',
    [leaderId]
  );

  const [subordinates] = await pool.execute(
    'SELECT id, nome, cargo FROM usuarios WHERE lider_id = ? AND status = ?',
    [leaderId, 'ativo']
  );

  const memberIds = subordinates.map(s => s.id);
  if (memberIds.length === 0) {
    return {
      lider: leader[0],
      periodo: { inicio: startDate, fim: endDate },
      resumo: { total_membros: 0, participacao: 0, media_score: 0 },
      membros: [],
      distribuicao_risco: { baixo: 0, moderado: 0, alto: 0, critico: 0 }
    };
  }

  const placeholders = memberIds.map(() => '?').join(',');

  const [assessmentStats] = await pool.execute(
    `SELECT
       a.usuario_id,
       COUNT(*) as total,
       AVG(a.score_risco) as media_score,
       MAX(a.score_risco) as max_score
     FROM avaliacoes a
     WHERE a.usuario_id IN (${placeholders})
       AND a.data BETWEEN ? AND ?
       AND a.completada = TRUE
     GROUP BY a.usuario_id`,
    [...memberIds, startDate, endDate]
  );

  const [riskDist] = await pool.execute(
    `SELECT a.nivel_risco, COUNT(*) as total
     FROM avaliacoes a
     WHERE a.usuario_id IN (${placeholders})
       AND a.data BETWEEN ? AND ?
       AND a.completada = TRUE
     GROUP BY a.nivel_risco`,
    [...memberIds, startDate, endDate]
  );

  const statsMap = {};
  for (const stat of assessmentStats) {
    statsMap[stat.usuario_id] = stat;
  }

  const membros = subordinates.map(sub => {
    const stats = statsMap[sub.id];
    return {
      id: sub.id,
      nome: sub.nome,
      cargo: sub.cargo,
      total_avaliacoes: stats ? stats.total : 0,
      media_score: stats ? Math.round(parseFloat(stats.media_score) * 100) / 100 : null,
      max_score: stats ? parseFloat(stats.max_score) : null
    };
  });

  const participantCount = assessmentStats.length;
  const overallAvg = assessmentStats.length > 0
    ? assessmentStats.reduce((s, a) => s + parseFloat(a.media_score), 0) / assessmentStats.length
    : 0;

  const distribuicao = { baixo: 0, moderado: 0, alto: 0, critico: 0 };
  for (const rd of riskDist) {
    distribuicao[rd.nivel_risco] = rd.total;
  }

  return {
    lider: leader[0],
    periodo: { inicio: startDate, fim: endDate },
    resumo: {
      total_membros: subordinates.length,
      participacao: Math.round((participantCount / subordinates.length) * 100),
      media_score: Math.round(overallAvg * 100) / 100
    },
    membros,
    distribuicao_risco: distribuicao
  };
}

async function generateSectorReport(setor, dateRange = {}) {
  const startDate = dateRange.startDate || daysAgoDateString(30);
  const endDate = dateRange.endDate || todayDateString();

  const [employees] = await pool.execute(
    'SELECT id, nome FROM usuarios WHERE setor = ? AND status = ?',
    [setor, 'ativo']
  );

  const empIds = employees.map(e => e.id);
  if (empIds.length === 0) {
    return {
      setor,
      periodo: { inicio: startDate, fim: endDate },
      resumo: { total_funcionarios: 0, participacao: 0, media_score: 0 },
      distribuicao_risco: { baixo: 0, moderado: 0, alto: 0, critico: 0 },
      categorias: []
    };
  }

  const placeholders = empIds.map(() => '?').join(',');

  const [stats] = await pool.execute(
    `SELECT
       COUNT(DISTINCT a.usuario_id) as participantes,
       AVG(a.score_risco) as media_score,
       COUNT(*) as total_avaliacoes
     FROM avaliacoes a
     WHERE a.usuario_id IN (${placeholders})
       AND a.data BETWEEN ? AND ?
       AND a.completada = TRUE`,
    [...empIds, startDate, endDate]
  );

  const [riskDist] = await pool.execute(
    `SELECT a.nivel_risco, COUNT(*) as total
     FROM avaliacoes a
     WHERE a.usuario_id IN (${placeholders})
       AND a.data BETWEEN ? AND ?
       AND a.completada = TRUE
     GROUP BY a.nivel_risco`,
    [...empIds, startDate, endDate]
  );

  const [categoryAvgs] = await pool.execute(
    `SELECT p.categoria, AVG(r.valor) as media
     FROM respostas r
     JOIN perguntas p ON r.pergunta_id = p.id
     JOIN avaliacoes a ON r.avaliacao_id = a.id
     WHERE a.usuario_id IN (${placeholders})
       AND a.data BETWEEN ? AND ?
       AND a.completada = TRUE
     GROUP BY p.categoria
     ORDER BY media DESC`,
    [...empIds, startDate, endDate]
  );

  const distribuicao = { baixo: 0, moderado: 0, alto: 0, critico: 0 };
  for (const rd of riskDist) {
    distribuicao[rd.nivel_risco] = rd.total;
  }

  return {
    setor,
    periodo: { inicio: startDate, fim: endDate },
    resumo: {
      total_funcionarios: employees.length,
      participacao: stats[0].participantes ? Math.round((stats[0].participantes / employees.length) * 100) : 0,
      media_score: stats[0].media_score ? Math.round(parseFloat(stats[0].media_score) * 100) / 100 : 0,
      total_avaliacoes: stats[0].total_avaliacoes
    },
    distribuicao_risco: distribuicao,
    categorias: categoryAvgs.map(c => ({
      categoria: c.categoria,
      media: Math.round(parseFloat(c.media) * 100) / 100
    }))
  };
}

async function generatePDF(reportData, type = 'individual') {
  return new Promise((resolve, reject) => {
    try {
      const doc = new PDFDocument({ margin: 50 });
      const buffers = [];

      doc.on('data', chunk => buffers.push(chunk));
      doc.on('end', () => resolve(Buffer.concat(buffers)));
      doc.on('error', reject);

      doc.fontSize(20).text('Relatorio Psicossocial', { align: 'center' });
      doc.moveDown();
      doc.fontSize(12).text(`Tipo: ${type === 'individual' ? 'Individual' : type === 'equipe' ? 'Equipe' : 'Setor'}`, { align: 'center' });
      doc.text(`Gerado em: ${new Date().toLocaleDateString('pt-BR')}`, { align: 'center' });
      doc.moveDown(2);

      doc.moveTo(50, doc.y).lineTo(550, doc.y).stroke();
      doc.moveDown();

      if (type === 'individual' && reportData.usuario) {
        doc.fontSize(14).text('Dados do Funcionario');
        doc.moveDown(0.5);
        doc.fontSize(10);
        doc.text(`Nome: ${reportData.usuario.nome}`);
        doc.text(`Cargo: ${reportData.usuario.cargo || 'N/A'}`);
        doc.text(`Setor: ${reportData.usuario.setor || 'N/A'}`);
        doc.text(`Periodo: ${reportData.periodo.inicio} a ${reportData.periodo.fim}`);
        doc.moveDown();

        doc.fontSize(14).text('Resumo');
        doc.moveDown(0.5);
        doc.fontSize(10);
        doc.text(`Total de avaliacoes: ${reportData.resumo.total_avaliacoes}`);
        doc.text(`Media do score: ${reportData.resumo.media_score}`);
        doc.text(`Score mais recente: ${reportData.resumo.score_mais_recente || 'N/A'}`);
        doc.moveDown();

        if (reportData.categorias && reportData.categorias.length > 0) {
          doc.fontSize(14).text('Media por Categoria');
          doc.moveDown(0.5);
          doc.fontSize(10);
          for (const cat of reportData.categorias) {
            doc.text(`  ${cat.categoria}: ${cat.media}/5`);
          }
          doc.moveDown();
        }

        if (reportData.alertas && reportData.alertas.length > 0) {
          doc.fontSize(14).text('Alertas no Periodo');
          doc.moveDown(0.5);
          doc.fontSize(10);
          for (const alert of reportData.alertas) {
            doc.text(`  ${alert.tipo}: ${alert.total} ocorrencia(s)`);
          }
        }
      } else if (type === 'equipe' && reportData.lider) {
        doc.fontSize(14).text('Relatorio da Equipe');
        doc.moveDown(0.5);
        doc.fontSize(10);
        doc.text(`Lider: ${reportData.lider.nome}`);
        doc.text(`Periodo: ${reportData.periodo.inicio} a ${reportData.periodo.fim}`);
        doc.moveDown();

        doc.fontSize(14).text('Resumo');
        doc.moveDown(0.5);
        doc.fontSize(10);
        doc.text(`Total de membros: ${reportData.resumo.total_membros}`);
        doc.text(`Taxa de participacao: ${reportData.resumo.participacao}%`);
        doc.text(`Media do score: ${reportData.resumo.media_score}`);
        doc.moveDown();

        doc.fontSize(14).text('Distribuicao de Risco');
        doc.moveDown(0.5);
        doc.fontSize(10);
        const dr = reportData.distribuicao_risco;
        doc.text(`  Baixo: ${dr.baixo} | Moderado: ${dr.moderado} | Alto: ${dr.alto} | Critico: ${dr.critico}`);
        doc.moveDown();

        if (reportData.membros && reportData.membros.length > 0) {
          doc.fontSize(14).text('Membros da Equipe');
          doc.moveDown(0.5);
          doc.fontSize(10);
          for (const m of reportData.membros) {
            doc.text(`  ${m.nome} - Avaliacoes: ${m.total_avaliacoes} - Media: ${m.media_score || 'N/A'}`);
          }
        }
      } else if (type === 'setor') {
        doc.fontSize(14).text(`Relatorio do Setor: ${reportData.setor}`);
        doc.moveDown(0.5);
        doc.fontSize(10);
        doc.text(`Periodo: ${reportData.periodo.inicio} a ${reportData.periodo.fim}`);
        doc.moveDown();

        doc.fontSize(14).text('Resumo');
        doc.moveDown(0.5);
        doc.fontSize(10);
        doc.text(`Total de funcionarios: ${reportData.resumo.total_funcionarios}`);
        doc.text(`Taxa de participacao: ${reportData.resumo.participacao}%`);
        doc.text(`Media do score: ${reportData.resumo.media_score}`);
        doc.moveDown();

        doc.fontSize(14).text('Distribuicao de Risco');
        doc.moveDown(0.5);
        doc.fontSize(10);
        const dr = reportData.distribuicao_risco;
        doc.text(`  Baixo: ${dr.baixo} | Moderado: ${dr.moderado} | Alto: ${dr.alto} | Critico: ${dr.critico}`);
        doc.moveDown();

        if (reportData.categorias && reportData.categorias.length > 0) {
          doc.fontSize(14).text('Media por Categoria');
          doc.moveDown(0.5);
          doc.fontSize(10);
          for (const cat of reportData.categorias) {
            doc.text(`  ${cat.categoria}: ${cat.media}/5`);
          }
        }
      }

      doc.moveDown(2);
      doc.fontSize(8).text('Este relatorio e confidencial e destinado apenas para uso interno.', { align: 'center' });

      doc.end();
    } catch (error) {
      reject(error);
    }
  });
}

async function generateExcel(reportData, type = 'individual') {
  const workbook = new ExcelJS.Workbook();
  workbook.creator = 'Psicossocial API';
  workbook.created = new Date();

  if (type === 'individual' && reportData.usuario) {
    const sheet = workbook.addWorksheet('Relatorio Individual');

    sheet.columns = [
      { header: 'Campo', key: 'campo', width: 25 },
      { header: 'Valor', key: 'valor', width: 30 }
    ];

    sheet.addRow({ campo: 'Nome', valor: reportData.usuario.nome });
    sheet.addRow({ campo: 'Cargo', valor: reportData.usuario.cargo || 'N/A' });
    sheet.addRow({ campo: 'Setor', valor: reportData.usuario.setor || 'N/A' });
    sheet.addRow({ campo: 'Periodo', valor: `${reportData.periodo.inicio} a ${reportData.periodo.fim}` });
    sheet.addRow({ campo: 'Total Avaliacoes', valor: reportData.resumo.total_avaliacoes });
    sheet.addRow({ campo: 'Media Score', valor: reportData.resumo.media_score });
    sheet.addRow({ campo: 'Score Recente', valor: reportData.resumo.score_mais_recente || 'N/A' });

    if (reportData.evolucao && reportData.evolucao.length > 0) {
      const evoSheet = workbook.addWorksheet('Evolucao');
      evoSheet.columns = [
        { header: 'Data', key: 'data', width: 15 },
        { header: 'Score', key: 'score', width: 12 },
        { header: 'Nivel', key: 'nivel', width: 12 }
      ];
      for (const entry of reportData.evolucao) {
        evoSheet.addRow(entry);
      }
    }

    if (reportData.categorias && reportData.categorias.length > 0) {
      const catSheet = workbook.addWorksheet('Categorias');
      catSheet.columns = [
        { header: 'Categoria', key: 'categoria', width: 20 },
        { header: 'Media', key: 'media', width: 12 }
      ];
      for (const cat of reportData.categorias) {
        catSheet.addRow(cat);
      }
    }
  } else if (type === 'equipe' && reportData.lider) {
    const sheet = workbook.addWorksheet('Relatorio Equipe');

    sheet.columns = [
      { header: 'Campo', key: 'campo', width: 25 },
      { header: 'Valor', key: 'valor', width: 30 }
    ];

    sheet.addRow({ campo: 'Lider', valor: reportData.lider.nome });
    sheet.addRow({ campo: 'Periodo', valor: `${reportData.periodo.inicio} a ${reportData.periodo.fim}` });
    sheet.addRow({ campo: 'Total Membros', valor: reportData.resumo.total_membros });
    sheet.addRow({ campo: 'Participacao', valor: `${reportData.resumo.participacao}%` });
    sheet.addRow({ campo: 'Media Score', valor: reportData.resumo.media_score });

    if (reportData.membros && reportData.membros.length > 0) {
      const membrosSheet = workbook.addWorksheet('Membros');
      membrosSheet.columns = [
        { header: 'Nome', key: 'nome', width: 25 },
        { header: 'Cargo', key: 'cargo', width: 20 },
        { header: 'Avaliacoes', key: 'total_avaliacoes', width: 12 },
        { header: 'Media Score', key: 'media_score', width: 15 },
        { header: 'Max Score', key: 'max_score', width: 12 }
      ];
      for (const m of reportData.membros) {
        membrosSheet.addRow(m);
      }
    }
  } else if (type === 'setor') {
    const sheet = workbook.addWorksheet('Relatorio Setor');

    sheet.columns = [
      { header: 'Campo', key: 'campo', width: 25 },
      { header: 'Valor', key: 'valor', width: 30 }
    ];

    sheet.addRow({ campo: 'Setor', valor: reportData.setor });
    sheet.addRow({ campo: 'Periodo', valor: `${reportData.periodo.inicio} a ${reportData.periodo.fim}` });
    sheet.addRow({ campo: 'Total Funcionarios', valor: reportData.resumo.total_funcionarios });
    sheet.addRow({ campo: 'Participacao', valor: `${reportData.resumo.participacao}%` });
    sheet.addRow({ campo: 'Media Score', valor: reportData.resumo.media_score });

    if (reportData.categorias && reportData.categorias.length > 0) {
      const catSheet = workbook.addWorksheet('Categorias');
      catSheet.columns = [
        { header: 'Categoria', key: 'categoria', width: 20 },
        { header: 'Media', key: 'media', width: 12 }
      ];
      for (const cat of reportData.categorias) {
        catSheet.addRow(cat);
      }
    }
  }

  const buffer = await workbook.xlsx.writeBuffer();
  return buffer;
}

module.exports = {
  generateIndividualReport,
  generateTeamReport,
  generateSectorReport,
  generatePDF,
  generateExcel
};
