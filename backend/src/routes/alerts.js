const { Router } = require('express');
const alertController = require('../controllers/alertController');
const authMiddleware = require('../middleware/auth');
const authorize = require('../middleware/rbac');
const { idParamValidation } = require('../middleware/validator');

const router = Router();

router.use(authMiddleware);

router.get('/', alertController.listAlerts);
router.get('/nao-lidos', alertController.countUnread);
router.get('/agregado', authorize(['administrador', 'lider']), alertController.getAggregated);
router.put('/:id/lido', idParamValidation, alertController.markAsRead);

module.exports = router;
