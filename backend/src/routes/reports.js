const { Router } = require('express');
const reportController = require('../controllers/reportController');
const authMiddleware = require('../middleware/auth');
const authorize = require('../middleware/rbac');

const router = Router();

router.use(authMiddleware);
router.use(authorize(['administrador', 'lider']));

router.get('/individual/:userId', reportController.getIndividualReport);
router.get('/equipe/:liderId', reportController.getTeamReport);
router.get('/setor/:setor', reportController.getSectorReport);
router.get('/exportar/pdf', reportController.exportPdf);
router.get('/exportar/excel', reportController.exportExcel);

module.exports = router;
