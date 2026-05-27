require('dotenv').config();

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const swaggerUi = require('swagger-ui-express');
const path = require('path');

const logger = require('./utils/logger');
const initDb = require('./config/initDb');
const errorHandler = require('./middleware/errorHandler');

const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/users');
const assessmentRoutes = require('./routes/assessments');
const questionRoutes = require('./routes/questions');
const emergencyRoutes = require('./routes/emergencies');
const alertRoutes = require('./routes/alerts');
const dashboardRoutes = require('./routes/dashboard');
const reportRoutes = require('./routes/reports');

const app = express();

app.use(helmet());

const corsOrigins = (process.env.CORS_ORIGINS || '*').split(',').map(s => s.trim());
app.use(cors({
  origin: corsOrigins.includes('*') ? true : corsOrigins,
  credentials: true
}));

app.use(morgan('combined'));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

const swaggerDocument = require(path.join(__dirname, '..', 'swagger.json'));
app.use('/api/docs', swaggerUi.serve, swaggerUi.setup(swaggerDocument, {
  customCss: '.swagger-ui .topbar { display: none }',
  customSiteTitle: 'Psicossocial API - Documentacao'
}));

app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/usuarios', userRoutes);
app.use('/api/v1/avaliacoes', assessmentRoutes);
app.use('/api/v1/perguntas', questionRoutes);
app.use('/api/v1/emergencias', emergencyRoutes);
app.use('/api/v1/alertas', alertRoutes);
app.use('/api/v1/dashboard', dashboardRoutes);
app.use('/api/v1/relatorios', reportRoutes);

app.get('/api/v1/health', (_req, res) => {
  res.json({ success: true, data: { status: 'ok', timestamp: new Date().toISOString() }, message: 'API funcionando' });
});

app.use((_req, res) => {
  res.status(404).json({ success: false, data: null, message: 'Rota nao encontrada' });
});

app.use(errorHandler);

const PORT = process.env.PORT || 3000;

async function start() {
  try {
    await initDb();
  } catch (err) {
    logger.error('Falha ao inicializar o banco de dados', {
      code: err.code,
      message: err.message
    });
    process.exit(1);
  }

  app.listen(PORT, () => {
    logger.info(`Psicossocial API rodando na porta ${PORT}`);
    logger.info(`Documentacao disponivel em http://localhost:${PORT}/api/docs`);
  });
}

if (require.main === module) {
  start();
}

module.exports = app;
