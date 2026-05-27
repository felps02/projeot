const pool = require('../config/database');
const PDFDocument = require('pdfkit');
const ExcelJS = require('exceljs');
const { daysAgoDateString, todayDateString } = require('../utils/helpers');
const { K_MIN, shouldSuppress, SUPRIMIDO_MOTIVO } = require('../utils/privacy');

async function generateIndividualReport(userId, dateRange = {}) {
  const startDate = dateRange.startDate || daysAgoDateString(30);
  const endDate = dateRange.endDate || todayDateString();

  const [userRows] = await pool.execute(
    'SELECT id, nome, email, cargo, setor, turno FROM usuarios WHERE id = ?',
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

  const [leaderRows] = await pool.execute(
    "SELECT id, nome, setor, turno FROM usuarios WHERE id = ? AND perfil = 'lider'",
    [leaderId]
  );
  if (leaderRows.length === 0) return null;
  const leader = leaderRows[0];

  const [subordinates] = await pool.execute(
    "SELECT id FROM usuarios WHERE lider_id = ? AND status = 'ativo'",
    [leaderId]
  );

  const memberIds = subordinates.map(s => s.id);
  const totalMembros = memberIds.length;

  if (shouldSuppress(totalMembros)) {
    return {
      lider: { id: leader.id, setor: leader.setor, turno: leader.turno },
      periodo: { inicio: startDate, fim: endDate, k_minimo: K_MIN },
      suprimido: true,
      motivo: SUPRIMIDO_MOTIVO,
      resumo: null,
      distribuicao_risco: null,
      categorias: []
    };
  }

  const placeholders = memberIds.map(() => '?').join(',');

  const [aggregateStats] = await pool.execute(
    `SELECT
       COUNT(DISTINCT a.usuario_id) as participantes,
       AVG(a.score_risco) as media_score,
       COUNT(*) as total_avaliacoes
     FROM avaliacoes a
     WHERE a.usuario_id IN (${placeholders})
       AND a.data BETWEEN ? AND ?
       AND a.completada = TRUE`,
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
    [...memberIds, startDate, endDate]
  );

  const distribuicao = { baixo: 0, moderado: 0, alto: 0, critico: 0 };
  for (const rd of riskDist) distribuicao[rd.nivel_risco] = rd.total;

  return {
    lider: { id: leader.id, setor: leader.setor, turno: leader.turno },
    periodo: { inicio: startDate, fim: endDate, k_minimo: K_MIN },
    resumo: {
      total_membros: totalMembros,
      participacao: aggregateStats[0].participantes
        ? Math.round((aggregateStats[0].participantes / totalMembros) * 100)
        : 0,
      media_score: aggregateStats[0].media_score
        ? Math.round(parseFloat(aggregateStats[0].media_score) * 100) / 100
        : 0,
      total_avaliacoes: aggregateStats[0].total_avaliacoes
    },
    distribuicao_risco: distribuicao,
    categorias: categoryAvgs.map(c => ({
      categoria: c.categoria,
      media: Math.round(parseFloat(c.media) * 100) / 100
    }))
  };
}

async function generateSectorReport(setor, dateRange = {}) {
  const startDate = dateRange.startDate || daysAgoDateString(30);
  const endDate = dateRange.endDate || todayDateString();

  const [employees] = await pool.execute(
    "SELECT id FROM usuarios WHERE setor = ? AND status = 'ativo'",
    [setor]
  );

  const empIds = employees.map(e => e.id);
  const totalFuncionarios = empIds.length;

  if (shouldSuppress(totalFuncionarios)) {
    return {
      setor,
      periodo: { inicio: startDate, fim: endDate, k_minimo: K_MIN },
      suprimido: true,
      motivo: SUPRIMIDO_MOTIVO,
      resumo: null,
      distribuicao_risco: null,
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
  for (const rd of riskDist) distribuicao[rd.nivel_risco] = rd.total;

  return {
    setor,
    periodo: { inicio: startDate, fim: endDate, k_minimo: K_MIN },
    resumo: {
      total_funcionarios: totalFuncionarios,
      participacao: stats[0].participantes
        ? Math.round((stats[0].participantes / totalFuncionarios) * 100)
        : 0,
      media_score: stats[0].media_score
        ? Math.round(parseFloat(stats[0].media_score) * 100) / 100
        : 0,
      total_avaliacoes: stats[0].total_avaliacoes
    },
    distribuicao_risco: distribuicao,
    categorias: categoryAvgs.map(c => ({
      categoria: c.categoria,
      media: Math.round(parseFloat(c.media) * 100) / 100
    }))
  };
}

async function generatePDF(reportData, type = 'setor') {
  return new Promise((resolve, reject) => {
    try {
      const doc = new PDFDocument({ margin: 50 });
      const buffers = [];

      doc.on('data', chunk => buffers.push(chunk));
      doc.on('end', () => resolve(Buffer.concat(buffers)));
      doc.on('error', reject);

      doc.fontSize(20).text('Relatorio Psicossocial', { align: 'center' });
      doc.moveDown();
      const titulo = type === 'individual' ? 'Individual'
        : type === 'equipe' ? 'Equipe (Agregado)'
        : 'Setor (Agregado)';
      doc.fontSize(12).text(`Tipo: ${titulo}`, { align: 'center' });
      doc.text(`Gerado em: ${new Date().toLocaleDateString('pt-BR')}`, { align: 'center' });
      doc.moveDown(2);
      doc.moveTo(50, doc.y).lineTo(550, doc.y).stroke();
      doc.moveDown();

      if (reportData.suprimido) {
        doc.fontSize(14).text('Relatorio suprimido por LGPD');
        doc.moveDown(0.5);
        doc.fontSize(10).text(reportData.motivo || SUPRIMIDO_MOTIVO);
      } else if (type === 'individual' && reportData.usuario) {
        doc.fontSize(14).text('Dados do Funcionario');
        doc.moveDown(0.5);
        doc.fontSize(10);
        doc.text(`Nome: ${reportData.usuario.nome}`);
        doc.text(`Cargo: ${reportData.usuario.cargo || 'N/A'}`);
        doc.text(`Setor: ${reportData.usuario.setor || 'N/A'}`);
        doc.text(`Turno: ${reportData.usuario.turno || 'N/A'}`);
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
        }
      } else if (type === 'equipe') {
        doc.fontSize(14).text('Relatorio Agregado de Equipe');
        doc.moveDown(0.5);
        doc.fontSize(10);
        if (reportData.lider) {
          doc.text(`Setor: ${reportData.lider.setor || 'N/A'} | Turno: ${reportData.lider.turno || 'N/A'}`);
        }
        doc.text(`Periodo: ${reportData.periodo.inicio} a ${reportData.periodo.fim}`);
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

        if (reportData.categorias && reportData.categorias.length > 0) {
          doc.fontSize(14).text('Media por Categoria');
          doc.moveDown(0.5);
          doc.fontSize(10);
          for (const cat of reportData.categorias) {
            doc.text(`  ${cat.categoria}: ${cat.media}/5`);
          }
        }
      } else if (type === 'setor') {
        doc.fontSize(14).text(`Relatorio Agregado do Setor: ${reportData.setor}`);
        doc.moveDown(0.5);
        doc.fontSize(10);
        doc.text(`Periodo: ${reportData.periodo.inicio} a ${reportData.periodo.fim}`);
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
      doc.fontSize(8).text(`Este relatorio e confidencial. Dados de equipe/setor sao agregados conforme LGPD (k>=${K_MIN}).`, { align: 'center' });

      doc.end();
    } catch (error) {
      reject(error);
    }
  });
}

async function generateExcel(reportData, type = 'setor') {
  const workbook = new ExcelJS.Workbook();
  workbook.creator = 'Psicossocial API';
  workbook.created = new Date();

  const main = workbook.addWorksheet('Relatorio');
  main.columns = [
    { header: 'Campo', key: 'campo', width: 25 },
    { header: 'Valor', key: 'valor', width: 35 }
  ];

  if (reportData.suprimido) {
    main.addRow({ campo: 'Status', valor: 'SUPRIMIDO POR LGPD' });
    main.addRow({ campo: 'Motivo', valor: reportData.motivo || SUPRIMIDO_MOTIVO });
    main.addRow({ campo: 'Periodo', valor: `${reportData.periodo.inicio} a ${reportData.periodo.fim}` });
  } else if (type === 'individual' && reportData.usuario) {
    main.addRow({ campo: 'Nome', valor: reportData.usuario.nome });
    main.addRow({ campo: 'Cargo', valor: reportData.usuario.cargo || 'N/A' });
    main.addRow({ campo: 'Setor', valor: reportData.usuario.setor || 'N/A' });
    main.addRow({ campo: 'Turno', valor: reportData.usuario.turno || 'N/A' });
    main.addRow({ campo: 'Periodo', valor: `${reportData.periodo.inicio} a ${reportData.periodo.fim}` });
    main.addRow({ campo: 'Total Avaliacoes', valor: reportData.resumo.total_avaliacoes });
    main.addRow({ campo: 'Media Score', valor: reportData.resumo.media_score });
    main.addRow({ campo: 'Score Recente', valor: reportData.resumo.score_mais_recente || 'N/A' });

    if (reportData.evolucao && reportData.evolucao.length > 0) {
      const evoSheet = workbook.addWorksheet('Evolucao');
      evoSheet.columns = [
        { header: 'Data', key: 'data', width: 15 },
        { header: 'Score', key: 'score', width: 12 },
        { header: 'Nivel', key: 'nivel', width: 12 }
      ];
      for (const entry of reportData.evolucao) evoSheet.addRow(entry);
    }
  } else if (type === 'equipe') {
    if (reportData.lider) {
      main.addRow({ campo: 'Setor', valor: reportData.lider.setor || 'N/A' });
      main.addRow({ campo: 'Turno', valor: reportData.lider.turno || 'N/A' });
    }
    main.addRow({ campo: 'Periodo', valor: `${reportData.periodo.inicio} a ${reportData.periodo.fim}` });
    main.addRow({ campo: 'Total Membros', valor: reportData.resumo.total_membros });
    main.addRow({ campo: 'Participacao', valor: `${reportData.resumo.participacao}%` });
    main.addRow({ campo: 'Media Score', valor: reportData.resumo.media_score });
    main.addRow({ campo: 'Distribuicao Baixo', valor: reportData.distribuicao_risco.baixo });
    main.addRow({ campo: 'Distribuicao Moderado', valor: reportData.distribuicao_risco.moderado });
    main.addRow({ campo: 'Distribuicao Alto', valor: reportData.distribuicao_risco.alto });
    main.addRow({ campo: 'Distribuicao Critico', valor: reportData.distribuicao_risco.critico });
  } else if (type === 'setor') {
    main.addRow({ campo: 'Setor', valor: reportData.setor });
    main.addRow({ campo: 'Periodo', valor: `${reportData.periodo.inicio} a ${reportData.periodo.fim}` });
    main.addRow({ campo: 'Total Funcionarios', valor: reportData.resumo.total_funcionarios });
    main.addRow({ campo: 'Participacao', valor: `${reportData.resumo.participacao}%` });
    main.addRow({ campo: 'Media Score', valor: reportData.resumo.media_score });
    main.addRow({ campo: 'Distribuicao Baixo', valor: reportData.distribuicao_risco.baixo });
    main.addRow({ campo: 'Distribuicao Moderado', valor: reportData.distribuicao_risco.moderado });
    main.addRow({ campo: 'Distribuicao Alto', valor: reportData.distribuicao_risco.alto });
    main.addRow({ campo: 'Distribuicao Critico', valor: reportData.distribuicao_risco.critico });
  }

  if (reportData.categorias && reportData.categorias.length > 0) {
    const catSheet = workbook.addWorksheet('Categorias');
    catSheet.columns = [
      { header: 'Categoria', key: 'categoria', width: 20 },
      { header: 'Media', key: 'media', width: 12 }
    ];
    for (const cat of reportData.categorias) catSheet.addRow(cat);
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
