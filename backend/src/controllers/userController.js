const User = require('../models/User');
const AuditLog = require('../models/AuditLog');
const { successResponse, errorResponse, paginationParams } = require('../utils/helpers');

async function createUser(req, res, next) {
  try {
    const { nome, email, senha, cargo, perfil, setor, turno } = req.body;
    let { lider_id } = req.body;

    const actor = req.user;
    const requestedPerfil = perfil || 'funcionario';

    if (actor.perfil === 'lider') {
      if (requestedPerfil !== 'funcionario') {
        return errorResponse(res, 'Lideres so podem criar usuarios do tipo funcionario', 403);
      }
      lider_id = actor.id;
    } else if (actor.perfil === 'administrador') {
      if (!['lider', 'funcionario', 'administrador'].includes(requestedPerfil)) {
        return errorResponse(res, 'Perfil invalido', 400);
      }
      if (requestedPerfil === 'funcionario') {
        if (!lider_id) {
          return errorResponse(res, 'lider_id e obrigatorio para criar funcionarios', 400);
        }
        const validLeader = await User.isValidLeader(lider_id);
        if (!validLeader) {
          return errorResponse(res, 'lider_id nao corresponde a um lider ativo', 400);
        }
      } else {
        lider_id = null;
      }
    } else {
      return errorResponse(res, 'Acesso negado. Funcionarios nao podem criar usuarios.', 403);
    }

    const existingUser = await User.findByEmail(email);
    if (existingUser) {
      return errorResponse(res, 'Email ja cadastrado', 409);
    }

    const user = await User.create({
      nome, email, senha, cargo,
      perfil: requestedPerfil,
      setor, turno, lider_id
    });

    AuditLog.log(req, {
      acao: 'user.create',
      recurso: 'usuario',
      recurso_id: user.id,
      detalhes: `criado perfil=${requestedPerfil} por ${actor.perfil}#${actor.id}`
    });

    return successResponse(res, user, 'Usuario criado com sucesso', 201);
  } catch (error) {
    next(error);
  }
}

async function listUsers(req, res, next) {
  try {
    const { page, limit, offset } = paginationParams(req.query);
    const filters = { limit, offset };

    if (req.query.status) filters.status = req.query.status;
    if (req.query.perfil) filters.perfil = req.query.perfil;
    if (req.query.setor) filters.setor = req.query.setor;
    if (req.query.turno) filters.turno = req.query.turno;

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

    const isSelf = user.id === req.user.id;
    const isAdmin = req.user.perfil === 'administrador';
    const isOwnSubordinate = req.user.perfil === 'lider' && user.lider_id === req.user.id;

    if (!isSelf && !isAdmin && !isOwnSubordinate) {
      return errorResponse(res, 'Acesso negado', 403);
    }

    if (isAdmin && !isSelf) {
      AuditLog.log(req, {
        acao: 'user.view',
        recurso: 'usuario',
        recurso_id: user.id,
        detalhes: 'admin visualizou perfil individual'
      });
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

    const isSelf = existingUser.id === req.user.id;
    const isAdmin = req.user.perfil === 'administrador';
    const isOwnSubordinate = req.user.perfil === 'lider' && existingUser.lider_id === req.user.id;

    if (!isSelf && !isAdmin && !isOwnSubordinate) {
      return errorResponse(res, 'Acesso negado', 403);
    }

    const selfFields = ['nome', 'email', 'senha'];
    const leaderManagedFields = ['nome', 'email', 'cargo', 'setor', 'turno', 'status'];
    const adminFields = ['nome', 'email', 'cargo', 'perfil', 'setor', 'turno', 'lider_id', 'status', 'senha'];

    let allowedFields;
    if (isAdmin) {
      allowedFields = adminFields;
    } else if (isOwnSubordinate) {
      allowedFields = leaderManagedFields;
    } else {
      allowedFields = selfFields;
    }

    if (isAdmin && isSelf && req.body.perfil && req.body.perfil !== 'administrador') {
      return errorResponse(res, 'Admin nao pode rebaixar o proprio perfil', 400);
    }

    const updateData = {};
    for (const field of allowedFields) {
      if (req.body[field] !== undefined) {
        updateData[field] = req.body[field];
      }
    }

    if (updateData.lider_id !== undefined && updateData.lider_id !== null) {
      const valid = await User.isValidLeader(updateData.lider_id);
      if (!valid) {
        return errorResponse(res, 'lider_id nao corresponde a um lider ativo', 400);
      }
    }

    const user = await User.update(req.params.id, updateData);

    AuditLog.log(req, {
      acao: 'user.update',
      recurso: 'usuario',
      recurso_id: user.id,
      detalhes: `campos=${Object.keys(updateData).join(',')}`
    });

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

    if (existingUser.id === req.user.id) {
      return errorResponse(res, 'Voce nao pode desativar a si mesmo', 400);
    }

    if (existingUser.perfil === 'administrador') {
      const adminCount = await User.countByPerfil('administrador');
      if (adminCount <= 1) {
        return errorResponse(res, 'Nao e possivel desativar o ultimo administrador', 400);
      }
    }

    const user = await User.delete(req.params.id);

    AuditLog.log(req, {
      acao: 'user.delete',
      recurso: 'usuario',
      recurso_id: user.id,
      detalhes: `desativado perfil=${existingUser.perfil}`
    });

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

module.exports = { createUser, listUsers, getUser, updateUser, deleteUser, getSubordinates };
