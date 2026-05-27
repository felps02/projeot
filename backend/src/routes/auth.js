const { Router } = require('express');
const authController = require('../controllers/authController');
const authMiddleware = require('../middleware/auth');
const { loginValidation } = require('../middleware/validator');

const router = Router();

router.post('/login', loginValidation, authController.login);
router.get('/me', authMiddleware, authController.me);

module.exports = router;
