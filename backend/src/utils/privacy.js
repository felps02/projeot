const K_MIN = parseInt(process.env.K_ANONYMITY_MIN, 10) || 5;

const SUPRIMIDO_MOTIVO = `Dados insuficientes para exibicao (minimo ${K_MIN} pessoas no grupo).`;

function shouldSuppress(count) {
  return count == null || count < K_MIN;
}

function suppressedGroup(extras = {}) {
  return {
    ...extras,
    suprimido: true,
    motivo: SUPRIMIDO_MOTIVO,
    total: null,
    valor: null
  };
}

function applyKAnonymity(rows, getCount) {
  return rows.map(row => {
    const count = getCount(row);
    if (shouldSuppress(count)) {
      const { suprimido, motivo, total, valor, ...passthrough } = suppressedGroup(row);
      return { ...passthrough, suprimido, motivo, total, valor };
    }
    return row;
  });
}

module.exports = {
  K_MIN,
  SUPRIMIDO_MOTIVO,
  shouldSuppress,
  suppressedGroup,
  applyKAnonymity
};
