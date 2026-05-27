const { Router } = require('express');
const reportController = require('../controllers/reportController');
const authMiddleware = require('../middleware/auth');
const authorize = require('../middleware/rbac');

const router = Router();

router.use(authMiddleware);

router.get('/individual/:userId', authorize(['administrador']), reportController.getIndividualReport);
router.get('/equipe/:liderId', authorize(['administrador', 'lider']), reportController.getTeamReport);
router.get('/setor/:setor', authorize(['administrador', 'lider']), reportController.getSectorReport);
router.get('/exportar/pdf', authorize(['administrador', 'lider']), reportController.exportPdf);
router.get('/exportar/excel', authorize(['administrador', 'lider']), reportController.exportExcel);

module.exports = router;
