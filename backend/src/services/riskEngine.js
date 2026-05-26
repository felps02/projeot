const pool = require('../config/database');
const alertService = require('./alertService');

const RISK_LEVELS = {
  BAIXO: 'baixo',
  MODERADO: 'moderado',
  ALTO: 'alto',
  CRITICO: 'critico'
};

function calculateRiskScore(answers) {
  if (!answers || answers.length === 0) return 0;

  const maxPossibleScore = answers.length * 5;
  const totalScore = answers.reduce((sum, answer) => sum + answer.valor, 0);
  const normalizedScore = (totalScore / maxPossibleScore) * 100;

  return Math.round(normalizedScore * 100) / 100;
}

function classifyRisk(score) {
  if (score <= 25) return RISK_LEVELS.BAIXO;
  if (score <= 50) return RISK_LEVELS.MODERADO;
  if (score <= 75) return RISK_LEVELS.ALTO;
  return RISK_LEVELS.CRITICO;
}

async function analyzePatterns(userId) {
  const patterns = {
    consecutiveHighStress: false,
    risingAnxiety: false,
    suddenDrop: false,
    details: []
  };

  const [recentAssessments] = await pool.execute(
    `SELECT a.id, a.data, a.score_risco, a.nivel_risco
     FROM avaliacoes a
     WHERE a.usuario_id = ? AND a.completada = TRUE
     ORDER BY a.data DESC
     LIMIT 7`,
    [userId]
  );

  if (recentAssessments.length < 2) return patterns;

  let consecutiveHigh = 0;
  for (const assessment of recentAssessments) {
    if (assessment.nivel_risco === 'alto' || assessment.nivel_risco === 'critico') {
      consecutiveHigh++;
    } else {
      break;
    }
  }

  if (consecutiveHigh >= 3) {
    patterns.consecutiveHighStress = true;
    patterns.details.push(`${consecutiveHigh} dias consecutivos com risco alto ou critico`);
  }

  if (recentAssessments.length >= 3) {
    const recent3 = recentAssessments.slice(0, 3);
    const [answersRecent] = await pool.execute(
      `SELECT r.avaliacao_id, r.valor, p.categoria
       FROM respostas r
       JOIN perguntas p ON r.pergunta_id = p.id
       WHERE r.avaliacao_id IN (?, ?, ?) AND p.categoria = 'ansiedade'`,
      [recent3[0].id, recent3[1].id, recent3[2].id]
    );

    const anxietyByAssessment = {};
    for (const ans of answersRecent) {
      if (!anxietyByAssessment[ans.avaliacao_id]) {
        anxietyByAssessment[ans.avaliacao_id] = [];
      }
      anxietyByAssessment[ans.avaliacao_id].push(ans.valor);
    }

    const averages = recent3.map(a => {
      const values = anxietyByAssessment[a.id] || [];
      return values.length > 0 ? values.reduce((s, v) => s + v, 0) / values.length : 0;
    });

    if (averages[0] > averages[1] && averages[1] > averages[2] && averages[0] > 3) {
      patterns.risingAnxiety = true;
      patterns.details.push('Tendencia crescente de ansiedade nos ultimos 3 dias');
    }
  }

  if (recentAssessments.length >= 2) {
    const scoreDiff = recentAssessments[0].score_risco - recentAssessments[1].score_risco;
    if (scoreDiff >= 30) {
      patterns.suddenDrop = true;
      patterns.details.push(`Aumento subito de ${scoreDiff.toFixed(1)} pontos no score de risco`);
    }
  }

  return patterns;
}

async function generateAlerts(userId, assessment) {
  const alerts = [];

  if (assessment.nivel_risco === 'critico') {
    const alert = await alertService.createAlert({
      usuario_id: userId,
      tipo: 'risco_alto',
      nivel: 'critico',
      descricao: `Score de risco critico: ${assessment.score_risco}. Intervencao imediata recomendada.`
    });
    alerts.push(alert);
    await alertService.notifyLeader(userId, 'risco_alto', `Funcionario com score critico: ${assessment.score_risco}`);
  } else if (assessment.nivel_risco === 'alto') {
    const alert = await alertService.createAlert({
      usuario_id: userId,
      tipo: 'risco_alto',
      nivel: 'alto',
      descricao: `Score de risco alto: ${assessment.score_risco}. Acompanhamento recomendado.`
    });
    alerts.push(alert);
    await alertService.notifyLeader(userId, 'risco_alto', `Funcionario com score alto: ${assessment.score_risco}`);
  }

  const patterns = await analyzePatterns(userId);

  if (patterns.consecutiveHighStress) {
    const alert = await alertService.createAlert({
      usuario_id: userId,
      tipo: 'padrao_emocional',
      nivel: 'alto',
      descricao: patterns.details.find(d => d.includes('consecutivos'))
    });
    alerts.push(alert);
    await alertService.notifyLeader(userId, 'padrao_emocional', patterns.details.find(d => d.includes('consecutivos')));
  }

  if (patterns.risingAnxiety) {
    const alert = await alertService.createAlert({
      usuario_id: userId,
      tipo: 'padrao_emocional',
      nivel: 'moderado',
      descricao: patterns.details.find(d => d.includes('ansiedade'))
    });
    alerts.push(alert);
  }

  if (patterns.suddenDrop) {
    const alert = await alertService.createAlert({
      usuario_id: userId,
      tipo: 'padrao_emocional',
      nivel: 'alto',
      descricao: patterns.details.find(d => d.includes('subito'))
    });
    alerts.push(alert);
    await alertService.notifyLeader(userId, 'padrao_emocional', patterns.details.find(d => d.includes('subito')));
  }

  return alerts;
}

module.exports = {
  calculateRiskScore,
  classifyRisk,
  analyzePatterns,
  generateAlerts
};
