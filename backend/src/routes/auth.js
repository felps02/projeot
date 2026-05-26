const { Router } = require('express');
const authController = require('../controllers/authController');
const authMiddleware = require('../middleware/auth');
const { loginValidation, registerValidation } = require('../middleware/validator');

const router = Router();

router.post('/login', loginValidation, authController.login);
router.post('/register', registerValidation, authController.register);
router.get('/me', authMiddleware, authController.me);

module.exports = router;
