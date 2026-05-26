const { Router } = require('express');
const dashboardController = require('../controllers/dashboardController');
const authMiddleware = require('../middleware/auth');
const authorize = require('../middleware/rbac');

const router = Router();

router.use(authMiddleware);
router.use(authorize(['administrador', 'lider']));

router.get('/resumo', dashboardController.getResumo);
router.get('/tendencias', dashboardController.getTendencias);
router.get('/heatmap', dashboardController.getHeatmap);
router.get('/kpis', dashboardController.getKpis);

module.exports = router;
