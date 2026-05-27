const { Router } = require('express');
const userController = require('../controllers/userController');
const authMiddleware = require('../middleware/auth');
const authorize = require('../middleware/rbac');
const {
  registerValidation,
  updateUserValidation,
  idParamValidation
} = require('../middleware/validator');

const router = Router();

router.use(authMiddleware);

router.post(
  '/',
  authorize(['administrador', 'lider']),
  registerValidation,
  userController.createUser
);

router.get('/', authorize(['administrador', 'lider']), userController.listUsers);
router.get('/:id', idParamValidation, userController.getUser);
router.put('/:id', idParamValidation, updateUserValidation, userController.updateUser);
router.delete('/:id', idParamValidation, authorize(['administrador']), userController.deleteUser);
router.get('/:id/subordinados', idParamValidation, authorize(['administrador', 'lider']), userController.getSubordinates);

module.exports = router;
