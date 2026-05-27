const pool = require('../config/database');
const { successResponse, todayDateString, daysAgoDateString } = require('../utils/helpers');
const { K_MIN, shouldSuppress, suppressedGroup } = require('../utils/privacy');

function buildScopeFilter(req) {
  const conditions = [];
  const params = [];
  if (req.query.setor) {
    conditions.push('u.setor = ?');
    params.push(req.query.setor);
  }
  if (req.query.turno) {
    conditions.push('u.turno = ?');
    params.push(req.query.turno);
  }
  return {
    sql: conditions.length ? ' AND ' + conditions.join(' AND ') : '',
    params
  };
}

async function getResumo(req, res, next) {
  try {
    const today = todayDateString();
    const scope = buildScopeFilter(req);

    const [empCount] = await pool.execute(
      `SELECT COUNT(*) as total FROM usuarios u
       WHERE u.status = 'ativo' AND u.perfil = 'funcionario' ${scope.sql}`,
      scope.params
    );

    const [todayParticipation] = await pool.execute(
      `SELECT COUNT(DISTINCT a.usuario_id) as participantes
       FROM avaliacoes a
       JOIN usuarios u ON a.usuario_id = u.id
       WHERE a.data = ? AND a.completada = TRUE ${scope.sql}`,
      [today, ...scope.params]
    );

    const [riskDist] = await pool.execute(
      `SELECT a.nivel_risco, COUNT(*) as total
       FROM avaliacoes a
       JOIN usuarios u ON a.usuario_id = u.id
       WHERE a.data = ? AND a.completada = TRUE ${scope.sql}
       GROUP BY a.nivel_risco`,
      [today, ...scope.params]
    );

    const [activeAlerts] = await pool.execute(
      `SELECT al.nivel, COUNT(*) as total
       FROM alertas al
       JOIN usuarios u ON al.usuario_id = u.id
       WHERE al.lido = FALSE ${scope.sql}
       GROUP BY al.nivel`,
      scope.params
    );

    const totalEmp = empCount[0].total;
    const participantes = todayParticipation[0].participantes;

    if (shouldSuppress(totalEmp)) {
      return successResponse(res, suppressedGroup({
        escopo: { setor: req.query.setor || null, turno: req.query.turno || null }
      }), 'Resumo do dashboard');
    }

    const taxaParticipacao = totalEmp > 0 ? Math.round((participantes / totalEmp) * 100) : 0;
    const distribuicao = { baixo: 0, moderado: 0, alto: 0, critico: 0 };
    for (const r of riskDist) distribuicao[r.nivel_risco] = r.total;

    const alertasPorNivel = { baixo: 0, moderado: 0, alto: 0, critico: 0 };
    let totalAlertas = 0;
    for (const a of activeAlerts) {
      alertasPorNivel[a.nivel] = a.total;
      totalAlertas += a.total;
    }

    return successResponse(res, {
      escopo: { setor: req.query.setor || null, turno: req.query.turno || null },
      total_funcionarios: totalEmp,
      participacao_hoje: { participantes, total: totalEmp, taxa: taxaParticipacao },
      distribuicao_risco: distribuicao,
      alertas_ativos: { total: totalAlertas, por_nivel: alertasPorNivel }
    }, 'Resumo do dashboard');
  } catch (error) {
    next(error);
  }
}

async function getTendencias(req, res, next) {
  try {
    const days = parseInt(req.query.dias, 10) || 30;
    const startDate = daysAgoDateString(days);
    const scope = buildScopeFilter(req);

    const [trends] = await pool.execute(
      `SELECT
         a.data,
         COUNT(*) as total_avaliacoes,
         COUNT(DISTINCT a.usuario_id) as pessoas_distintas,
         AVG(a.score_risco) as media_score
       FROM avaliacoes a
       JOIN usuarios u ON a.usuario_id = u.id
       WHERE a.data >= ? AND a.completada = TRUE ${scope.sql}
       GROUP BY a.data
       ORDER BY a.data ASC`,
      [startDate, ...scope.params]
    );

    const [categoryTrends] = await pool.execute(
      `SELECT
         a.data,
         p.categoria,
         COUNT(DISTINCT a.usuario_id) as pessoas_distintas,
         AVG(r.valor) as media
       FROM respostas r
       JOIN avaliacoes a ON r.avaliacao_id = a.id
       JOIN perguntas p ON r.pergunta_id = p.id
       JOIN usuarios u ON a.usuario_id = u.id
       WHERE a.data >= ? AND a.completada = TRUE ${scope.sql}
       GROUP BY a.data, p.categoria
       ORDER BY a.data ASC`,
      [startDate, ...scope.params]
    );

    return successResponse(res, {
      periodo: { inicio: startDate, dias: days, k_minimo: K_MIN },
      escopo: { setor: req.query.setor || null, turno: req.query.turno || null },
      evolucao_diaria: trends.map(t => shouldSuppress(t.pessoas_distintas)
        ? { data: t.data, ...suppressedGroup() }
        : {
            data: t.data,
            total_avaliacoes: t.total_avaliacoes,
            media_score: Math.round(parseFloat(t.media_score) * 100) / 100
          }
      ),
      categorias: categoryTrends.map(ct => shouldSuppress(ct.pessoas_distintas)
        ? { data: ct.data, categoria: ct.categoria, ...suppressedGroup() }
        : {
            data: ct.data,
            categoria: ct.categoria,
            media: Math.round(parseFloat(ct.media) * 100) / 100
          }
      )
    }, 'Tendencias');
  } catch (error) {
    next(error);
  }
}

async function getHeatmap(req, res, next) {
  try {
    const days = parseInt(req.query.dias, 10) || 30;
    const startDate = daysAgoDateString(days);
    const dimensao = req.query.dimensao === 'turno' ? 'turno' : 'setor';

    const groupCol = dimensao === 'turno' ? 'u.turno' : 'u.setor';
    const groupAlias = dimensao;
    const fallback = dimensao === 'turno' ? 'Sem Turno' : 'Sem Setor';

    const [rows] = await pool.execute(
      `SELECT
         COALESCE(${groupCol}, ?) as grupo,
         a.data,
         COUNT(DISTINCT a.usuario_id) as pessoas_distintas,
         AVG(a.score_risco) as media_score
       FROM avaliacoes a
       JOIN usuarios u ON a.usuario_id = u.id
       WHERE a.data >= ? AND a.completada = TRUE
       GROUP BY ${groupCol}, a.data
       ORDER BY grupo, a.data`,
      [fallback, startDate]
    );

    return successResponse(res, {
      tipo: groupAlias,
      periodo: { inicio: startDate, dias: days, k_minimo: K_MIN },
      dados: rows.map(r => shouldSuppress(r.pessoas_distintas)
        ? { grupo: r.grupo, data: r.data, ...suppressedGroup() }
        : {
            grupo: r.grupo,
            data: r.data,
            pessoas: r.pessoas_distintas,
            media_score: Math.round(parseFloat(r.media_score) * 100) / 100
          }
      )
    }, 'Dados do heatmap');
  } catch (error) {
    next(error);
  }
}

async function getKpis(req, res, next) {
  try {
    const last7 = daysAgoDateString(7);
    const last30 = daysAgoDateString(30);
    const scope = buildScopeFilter(req);

    const [avgScore7] = await pool.execute(
      `SELECT AVG(a.score_risco) as media, COUNT(DISTINCT a.usuario_id) as pessoas
       FROM avaliacoes a
       JOIN usuarios u ON a.usuario_id = u.id
       WHERE a.data >= ? AND a.completada = TRUE ${scope.sql}`,
      [last7, ...scope.params]
    );

    const [avgScore30] = await pool.execute(
      `SELECT AVG(a.score_risco) as media, COUNT(DISTINCT a.usuario_id) as pessoas
       FROM avaliacoes a
       JOIN usuarios u ON a.usuario_id = u.id
       WHERE a.data >= ? AND a.completada = TRUE ${scope.sql}`,
      [last30, ...scope.params]
    );

    const [totalActive] = await pool.execute(
      `SELECT COUNT(*) as total FROM usuarios u
       WHERE u.status = 'ativo' AND u.perfil = 'funcionario' ${scope.sql}`,
      scope.params
    );

    const [participation7] = await pool.execute(
      `SELECT COUNT(*) as checkins
       FROM avaliacoes a
       JOIN usuarios u ON a.usuario_id = u.id
       WHERE a.data >= ? AND a.completada = TRUE ${scope.sql}`,
      [last7, ...scope.params]
    );

    const [criticalCount] = await pool.execute(
      `SELECT COUNT(*) as total
       FROM avaliacoes a
       JOIN usuarios u ON a.usuario_id = u.id
       WHERE a.data >= ? AND a.completada = TRUE AND a.nivel_risco = 'critico' ${scope.sql}`,
      [last7, ...scope.params]
    );

    const [openEmergencies] = await pool.execute(
      `SELECT COUNT(*) as total
       FROM emergencias e
       JOIN usuarios u ON e.usuario_id = u.id
       WHERE e.status != 'resolvida' ${scope.sql}`,
      scope.params
    );

    if (shouldSuppress(totalActive[0].total)) {
      return successResponse(res, suppressedGroup({
        escopo: { setor: req.query.setor || null, turno: req.query.turno || null }
      }), 'KPIs');
    }

    const possibleCheckins = totalActive[0].total * 5;
    const taxaAdesao = possibleCheckins > 0
      ? Math.round((participation7[0].checkins / possibleCheckins) * 100)
      : 0;

    return successResponse(res, {
      escopo: { setor: req.query.setor || null, turno: req.query.turno || null },
      media_risco_7dias: avgScore7[0].media && !shouldSuppress(avgScore7[0].pessoas)
        ? Math.round(parseFloat(avgScore7[0].media) * 100) / 100
        : null,
      media_risco_30dias: avgScore30[0].media && !shouldSuppress(avgScore30[0].pessoas)
        ? Math.round(parseFloat(avgScore30[0].media) * 100) / 100
        : null,
      taxa_adesao_semanal: taxaAdesao,
      avaliacoes_criticas_semana: criticalCount[0].total,
      emergencias_abertas: openEmergencies[0].total,
      total_funcionarios_ativos: totalActive[0].total
    }, 'KPIs');
  } catch (error) {
    next(error);
  }
}

module.exports = { getResumo, getTendencias, getHeatmap, getKpis };
