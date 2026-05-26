const User = require('../models/User');
const { successResponse, errorResponse, paginationParams } = require('../utils/helpers');

async function listUsers(req, res, next) {
  try {
    const { page, limit, offset } = paginationParams(req.query);
    const filters = { limit, offset };

    if (req.query.status) filters.status = req.query.status;
    if (req.query.perfil) filters.perfil = req.query.perfil;
    if (req.query.setor) filters.setor = req.query.setor;

    if (req.user.perfil === 'lider') {
      filters.lider_id = req.user.id;
    }

    const users = await User.findAll(filters);
    const total = await User.countByFilters(filters);

    return successResponse(res, {
      usuarios: users,
      paginacao: { pagina: page, limite: limit, total }
    }, 'Lista de usuarios');
  } catch (error) {
    next(error);
  }
}

async function getUser(req, res, next) {
  try {
    const user = await User.findById(req.params.id);
    if (!user) {
      return errorResponse(res, 'Usuario nao encontrado', 404);
    }

    if (req.user.perfil === 'lider' && user.lider_id !== req.user.id && user.id !== req.user.id) {
      return errorResponse(res, 'Acesso negado', 403);
    }

    return successResponse(res, user, 'Dados do usuario');
  } catch (error) {
    next(error);
  }
}

async function updateUser(req, res, next) {
  try {
    const existingUser = await User.findById(req.params.id);
    if (!existingUser) {
      return errorResponse(res, 'Usuario nao encontrado', 404);
    }

    if (req.user.perfil === 'lider' && existingUser.lider_id !== req.user.id) {
      return errorResponse(res, 'Acesso negado', 403);
    }

    const allowedFields = ['nome', 'email', 'cargo', 'setor', 'lider_id', 'status'];
    if (req.user.perfil === 'administrador') {
      allowedFields.push('perfil');
    }

    const updateData = {};
    for (const field of allowedFields) {
      if (req.body[field] !== undefined) {
        updateData[field] = req.body[field];
      }
    }

    const user = await User.update(req.params.id, updateData);
    return successResponse(res, user, 'Usuario atualizado com sucesso');
  } catch (error) {
    next(error);
  }
}

async function deleteUser(req, res, next) {
  try {
    const existingUser = await User.findById(req.params.id);
    if (!existingUser) {
      return errorResponse(res, 'Usuario nao encontrado', 404);
    }

    const user = await User.delete(req.params.id);
    return successResponse(res, user, 'Usuario desativado com sucesso');
  } catch (error) {
    next(error);
  }
}

async function getSubordinates(req, res, next) {
  try {
    const targetId = parseInt(req.params.id, 10);

    if (req.user.perfil === 'lider' && req.user.id !== targetId) {
      return errorResponse(res, 'Acesso negado', 403);
    }

    const subordinates = await User.findSubordinates(targetId);
    return successResponse(res, subordinates, 'Lista de subordinados');
  } catch (error) {
    next(error);
  }
}

module.exports = { listUsers, getUser, updateUser, deleteUser, getSubordinates };
