const { Router } = require('express');
const assessmentController = require('../controllers/assessmentController');
const authMiddleware = require('../middleware/auth');
const { assessmentValidation, idParamValidation } = require('../middleware/validator');

const router = Router();

router.use(authMiddleware);

router.post('/', assessmentValidation, assessmentController.createAssessment);
router.get('/', assessmentController.listAssessments);
router.get('/hoje', assessmentController.checkToday);
router.get('/historico', assessmentController.getHistory);
router.get('/:id', idParamValidation, assessmentController.getAssessment);

module.exports = router;
