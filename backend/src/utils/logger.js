const LEVELS = { error: 0, warn: 1, info: 2, debug: 3 };
const configured = (process.env.LOG_LEVEL || 'info').toLowerCase();
const threshold = LEVELS[configured] !== undefined ? LEVELS[configured] : LEVELS.info;

function format(level, message, meta) {
  const entry = {
    ts: new Date().toISOString(),
    level
  };
  if (meta && typeof meta === 'object') {
    Object.assign(entry, meta);
  }
  entry.message = message;
  return JSON.stringify(entry);
}

function log(level, message, meta) {
  if (LEVELS[level] > threshold) return;
  const out = format(level, message, meta);
  if (level === 'error' || level === 'warn') {
    console.error(out);
  } else {
    console.log(out);
  }
}

module.exports = {
  error: (msg, meta) => log('error', msg, meta),
  warn: (msg, meta) => log('warn', msg, meta),
  info: (msg, meta) => log('info', msg, meta),
  debug: (msg, meta) => log('debug', msg, meta)
};
