const { Router } = require('express');
const emergencyController = require('../controllers/emergencyController');
const authMiddleware = require('../middleware/auth');
const authorize = require('../middleware/rbac');
const { emergencyValidation, emergencyStatusValidation } = require('../middleware/validator');

const router = Router();

router.use(authMiddleware);

router.post('/', emergencyValidation, emergencyController.createEmergency);
router.get('/', authorize(['administrador', 'lider']), emergencyController.listEmergencies);
router.get('/abertas', authorize(['administrador', 'lider']), emergencyController.getOpenEmergencies);
router.put('/:id/status', emergencyStatusValidation, authorize(['administrador', 'lider']), emergencyController.updateEmergencyStatus);

module.exports = router;
