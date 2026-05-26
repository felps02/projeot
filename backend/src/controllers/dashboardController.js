const pool = require('../config/database');
const { successResponse, todayDateString, daysAgoDateString } = require('../utils/helpers');

async function getResumo(req, res, next) {
  try {
    const today = todayDateString();
    const isLeader = req.user.perfil === 'lider';
    const leaderCondition = isLeader ? 'AND u.lider_id = ?' : '';
    const params = isLeader ? [req.user.id] : [];

    const [empCount] = await pool.execute(
      `SELECT COUNT(*) as total FROM usuarios u WHERE u.status = 'ativo' AND u.perfil = 'funcionario' ${leaderCondition}`,
      params
    );

    const [todayParticipation] = await pool.execute(
      `SELECT COUNT(DISTINCT a.usuario_id) as participantes
       FROM avaliacoes a
       JOIN usuarios u ON a.usuario_id = u.id
       WHERE a.data = ? AND a.completada = TRUE ${leaderCondition}`,
      [today, ...params]
    );

    const [riskDist] = await pool.execute(
      `SELECT a.nivel_risco, COUNT(*) as total
       FROM avaliacoes a
       JOIN usuarios u ON a.usuario_id = u.id
       WHERE a.data = ? AND a.completada = TRUE ${leaderCondition}
       GROUP BY a.nivel_risco`,
      [today, ...params]
    );

    const [activeAlerts] = await pool.execute(
      `SELECT al.nivel, COUNT(*) as total
       FROM alertas al
       JOIN usuarios u ON al.usuario_id = u.id
       WHERE al.lido = FALSE ${leaderCondition}
       GROUP BY al.nivel`,
      params
    );

    const totalEmp = empCount[0].total;
    const participantes = todayParticipation[0].participantes;
    const taxaParticipacao = totalEmp > 0 ? Math.round((participantes / totalEmp) * 100) : 0;

    const distribuicao = { baixo: 0, moderado: 0, alto: 0, critico: 0 };
    for (const r of riskDist) {
      distribuicao[r.nivel_risco] = r.total;
    }

    const alertasPorNivel = { baixo: 0, moderado: 0, alto: 0, critico: 0 };
    let totalAlertas = 0;
    for (const a of activeAlerts) {
      alertasPorNivel[a.nivel] = a.total;
      totalAlertas += a.total;
    }

    return successResponse(res, {
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
    const isLeader = req.user.perfil === 'lider';
    const leaderCondition = isLeader ? 'AND u.lider_id = ?' : '';
    const params = isLeader ? [startDate, req.user.id] : [startDate];

    const [trends] = await pool.execute(
      `SELECT
         a.data,
         COUNT(*) as total_avaliacoes,
         AVG(a.score_risco) as media_score,
         MIN(a.score_risco) as min_score,
         MAX(a.score_risco) as max_score
       FROM avaliacoes a
       JOIN usuarios u ON a.usuario_id = u.id
       WHERE a.data >= ? AND a.completada = TRUE ${leaderCondition}
       GROUP BY a.data
       ORDER BY a.data ASC`,
      params
    );

    const [categoryTrends] = await pool.execute(
      `SELECT
         a.data,
         p.categoria,
         AVG(r.valor) as media
       FROM respostas r
       JOIN avaliacoes a ON r.avaliacao_id = a.id
       JOIN perguntas p ON r.pergunta_id = p.id
       JOIN usuarios u ON a.usuario_id = u.id
       WHERE a.data >= ? AND a.completada = TRUE ${leaderCondition}
       GROUP BY a.data, p.categoria
       ORDER BY a.data ASC`,
      params
    );

    return successResponse(res, {
      periodo: { inicio: startDate, dias: days },
      evolucao_diaria: trends.map(t => ({
        data: t.data,
        total_avaliacoes: t.total_avaliacoes,
        media_score: Math.round(parseFloat(t.media_score) * 100) / 100,
        min_score: parseFloat(t.min_score),
        max_score: parseFloat(t.max_score)
      })),
      categorias: categoryTrends.map(ct => ({
        data: ct.data,
        categoria: ct.categoria,
        media: Math.round(parseFloat(ct.media) * 100) / 100
      }))
    }, 'Tendencias');
  } catch (error) {
    next(error);
  }
}

async function getHeatmap(req, res, next) {
  try {
    const days = parseInt(req.query.dias, 10) || 30;
    const startDate = daysAgoDateString(days);
    const isLeader = req.user.perfil === 'lider';

    let query;
    let params;

    if (isLeader) {
      query = `SELECT
                 u.nome as grupo,
                 a.data,
                 AVG(a.score_risco) as media_score
               FROM avaliacoes a
               JOIN usuarios u ON a.usuario_id = u.id
               WHERE a.data >= ? AND a.completada = TRUE AND u.lider_id = ?
               GROUP BY u.id, u.nome, a.data
               ORDER BY u.nome, a.data`;
      params = [startDate, req.user.id];
    } else {
      query = `SELECT
                 COALESCE(u.setor, 'Sem Setor') as grupo,
                 a.data,
                 AVG(a.score_risco) as media_score
               FROM avaliacoes a
               JOIN usuarios u ON a.usuario_id = u.id
               WHERE a.data >= ? AND a.completada = TRUE
               GROUP BY u.setor, a.data
               ORDER BY u.setor, a.data`;
      params = [startDate];
    }

    const [heatmapData] = await pool.execute(query, params);

    return successResponse(res, {
      tipo: isLeader ? 'equipe' : 'setor',
      periodo: { inicio: startDate, dias: days },
      dados: heatmapData.map(h => ({
        grupo: h.grupo,
        data: h.data,
        media_score: Math.round(parseFloat(h.media_score) * 100) / 100
      }))
    }, 'Dados do heatmap');
  } catch (error) {
    next(error);
  }
}

async function getKpis(req, res, next) {
  try {
    const today = todayDateString();
    const last7 = daysAgoDateString(7);
    const last30 = daysAgoDateString(30);
    const isLeader = req.user.perfil === 'lider';
    const leaderCondition = isLeader ? 'AND u.lider_id = ?' : '';
    const params7 = isLeader ? [last7, req.user.id] : [last7];
    const params30 = isLeader ? [last30, req.user.id] : [last30];

    const [avgScore7] = await pool.execute(
      `SELECT AVG(a.score_risco) as media
       FROM avaliacoes a
       JOIN usuarios u ON a.usuario_id = u.id
       WHERE a.data >= ? AND a.completada = TRUE ${leaderCondition}`,
      params7
    );

    const [avgScore30] = await pool.execute(
      `SELECT AVG(a.score_risco) as media
       FROM avaliacoes a
       JOIN usuarios u ON a.usuario_id = u.id
       WHERE a.data >= ? AND a.completada = TRUE ${leaderCondition}`,
      params30
    );

    const empParams = isLeader ? [req.user.id] : [];
    const [totalActive] = await pool.execute(
      `SELECT COUNT(*) as total FROM usuarios u WHERE u.status = 'ativo' AND u.perfil = 'funcionario' ${leaderCondition}`,
      empParams
    );

    const weekdays7 = 5;
    const [participation7] = await pool.execute(
      `SELECT COUNT(DISTINCT a.usuario_id, a.data) as checkins
       FROM avaliacoes a
       JOIN usuarios u ON a.usuario_id = u.id
       WHERE a.data >= ? AND a.completada = TRUE ${leaderCondition}`,
      params7
    );

    const possibleCheckins = totalActive[0].total * weekdays7;
    const taxaAdesao = possibleCheckins > 0
      ? Math.round((participation7[0].checkins / possibleCheckins) * 100)
      : 0;

    const [criticalCount] = await pool.execute(
      `SELECT COUNT(*) as total
       FROM avaliacoes a
       JOIN usuarios u ON a.usuario_id = u.id
       WHERE a.data >= ? AND a.completada = TRUE AND a.nivel_risco = 'critico' ${leaderCondition}`,
      params7
    );

    const [openEmergencies] = await pool.execute(
      `SELECT COUNT(*) as total
       FROM emergencias e
       JOIN usuarios u ON e.usuario_id = u.id
       WHERE e.status != 'resolvida' ${leaderCondition}`,
      empParams
    );

    return successResponse(res, {
      media_risco_7dias: avgScore7[0].media ? Math.round(parseFloat(avgScore7[0].media) * 100) / 100 : 0,
      media_risco_30dias: avgScore30[0].media ? Math.round(parseFloat(avgScore30[0].media) * 100) / 100 : 0,
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
