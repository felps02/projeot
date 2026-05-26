const { Router } = require('express');
const alertController = require('../controllers/alertController');
const authMiddleware = require('../middleware/auth');
const { idParamValidation } = require('../middleware/validator');

const router = Router();

router.use(authMiddleware);

router.get('/', alertController.listAlerts);
router.get('/nao-lidos', alertController.countUnread);
router.put('/:id/lido', idParamValidation, alertController.markAsRead);

module.exports = router;
