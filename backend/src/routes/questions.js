const { Router } = require('express');
const questionController = require('../controllers/questionController');
const authMiddleware = require('../middleware/auth');
const authorize = require('../middleware/rbac');
const { questionValidation, idParamValidation } = require('../middleware/validator');

const router = Router();

router.use(authMiddleware);

router.get('/', questionController.listQuestions);
router.get('/ativas', questionController.listActiveQuestions);
router.get('/:id', idParamValidation, questionController.getQuestion);
router.post('/', authorize(['administrador']), questionValidation, questionController.createQuestion);
router.put('/:id', idParamValidation, authorize(['administrador']), questionController.updateQuestion);
router.delete('/:id', idParamValidation, authorize(['administrador']), questionController.deleteQuestion);

module.exports = router;
