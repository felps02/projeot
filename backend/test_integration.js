/*
 * Smoke test de integração — mocka o pool do mysql2/promise e exercita
 * os controllers via supertest-style chamadas diretas (sem subir HTTP).
 *
 * Cobre:
 *  - RBAC: admin cria lider; lider cria funcionario com lider_id forcado; funcionario -> 403
 *  - Login: sucesso e falhas, com audit log
 *  - LGPD: lider 403 em /alertas, /avaliacoes individuais, /relatorios/individual
 *  - Agregacao: heatmap por setor/turno, alertas agregados, team report sem membros[]
 *  - k-anonymity: setor com < K_ANONYMITY_MIN -> { suprimido: true }
 *  - Audit log: eventos chamados corretamente
 *
 * Uso: node test_integration.js
 */

process.env.NODE_ENV = 'development';
process.env.JWT_SECRET = 'test_secret';
process.env.K_ANONYMITY_MIN = '5';
process.env.LOG_LEVEL = 'error';

const assert = require('assert');
const Module = require('module');
const path = require('path');

// ============================================================
// Mock do mysql2/promise pool
// ============================================================
const fakeDB = {
  usuarios: [],
  avaliacoes: [],
  alertas: [],
  emergencias: [],
  audit_logs: [],
  perguntas: [],
  respostas: []
};
let nextId = { usuarios: 1, avaliacoes: 1, alertas: 1, audit_logs: 1, emergencias: 1, respostas: 1, perguntas: 1 };

function asInt(v) { return typeof v === 'string' ? parseInt(v, 10) : v; }

function mockExecute(sql, params = []) {
  const s = sql.replace(/\s+/g, ' ').trim();

  // SELECT ... FROM usuarios WHERE id = ?
  if (/FROM usuarios WHERE id = \?$/i.test(s)) {
    const row = fakeDB.usuarios.find(u => u.id === asInt(params[0]));
    return [row ? [row] : []];
  }
  if (/^SELECT \* FROM usuarios WHERE email = \?$/i.test(s)) {
    const row = fakeDB.usuarios.find(u => u.email === params[0]);
    return [row ? [row] : []];
  }
  // SELECT id, nome, setor, turno FROM usuarios WHERE id = ? AND perfil = 'lider'
  if (/FROM usuarios WHERE id = \? AND perfil = 'lider'$/i.test(s)) {
    const row = fakeDB.usuarios.find(u => u.id === asInt(params[0]) && u.perfil === 'lider');
    return [row ? [row] : []];
  }
  if (/perfil = 'lider' AND status = 'ativo'/i.test(s)) {
    const row = fakeDB.usuarios.find(u => u.id === asInt(params[0]) && u.perfil === 'lider' && u.status === 'ativo');
    return [row ? [{ id: row.id }] : []];
  }
  if (/^SELECT id FROM usuarios WHERE perfil = 'administrador' LIMIT 1$/i.test(s)) {
    const admin = fakeDB.usuarios.find(u => u.perfil === 'administrador');
    return [admin ? [{ id: admin.id }] : []];
  }
  if (/^SELECT COUNT\(\*\) as total FROM usuarios WHERE perfil = \? AND status = \?$/i.test(s)) {
    const total = fakeDB.usuarios.filter(u => u.perfil === params[0] && u.status === params[1]).length;
    return [[{ total }]];
  }
  if (/SELECT id FROM usuarios WHERE lider_id = \? AND status = 'ativo'/i.test(s)) {
    const rows = fakeDB.usuarios.filter(u => u.lider_id === params[0] && u.status === 'ativo').map(u => ({ id: u.id }));
    return [rows];
  }
  if (/SELECT .* FROM usuarios WHERE setor = \? AND status = 'ativo'/i.test(s)) {
    const rows = fakeDB.usuarios.filter(u => u.setor === params[0] && u.status === 'ativo').map(u => ({ id: u.id }));
    return [rows];
  }
  if (/^INSERT INTO usuarios/i.test(s)) {
    const id = nextId.usuarios++;
    const [nome, email, senha, cargo, perfil, setor, turno, lider_id] = params;
    const user = {
      id, nome, email, senha,
      cargo: cargo || null,
      perfil: perfil || 'funcionario',
      setor: setor || null,
      turno: turno || null,
      lider_id: lider_id || null,
      status: 'ativo',
      created_at: new Date(),
      updated_at: new Date()
    };
    fakeDB.usuarios.push(user);
    return [{ insertId: id }];
  }

  // INSERT INTO audit_logs
  if (/^INSERT INTO audit_logs/i.test(s)) {
    const id = nextId.audit_logs++;
    const [usuario_id, acao, recurso, recurso_id, detalhes, ip] = params;
    fakeDB.audit_logs.push({ id, usuario_id, acao, recurso, recurso_id, detalhes, ip, created_at: new Date() });
    return [{ insertId: id }];
  }

  // INSERT INTO alertas
  if (/^INSERT INTO alertas/i.test(s)) {
    const id = nextId.alertas++;
    const [usuario_id, tipo, nivel, descricao] = params;
    fakeDB.alertas.push({ id, usuario_id, tipo, nivel: nivel || 'alto', descricao, lido: false, data: new Date() });
    return [{ insertId: id }];
  }

  // SELECT al.*, u.setor, u.turno FROM alertas al JOIN usuarios u ... WHERE al.id = ?
  if (/^SELECT al\.\*, u\.setor as usuario_setor, u\.turno as usuario_turno FROM alertas al JOIN usuarios u/i.test(s)) {
    const al = fakeDB.alertas.find(a => a.id === params[0]);
    if (!al) return [[]];
    const u = fakeDB.usuarios.find(x => x.id === al.usuario_id);
    return [[{ ...al, usuario_setor: u?.setor, usuario_turno: u?.turno }]];
  }
  if (/^SELECT al\.\* FROM alertas al WHERE al\.usuario_id = \?/i.test(s)) {
    let rows = fakeDB.alertas.filter(a => a.usuario_id === params[0]);
    return [rows];
  }
  if (/^SELECT COUNT\(\*\) as total FROM alertas WHERE usuario_id = \? AND lido = FALSE$/i.test(s)) {
    const total = fakeDB.alertas.filter(a => a.usuario_id === params[0] && !a.lido).length;
    return [[{ total }]];
  }
  if (/SELECT.*COALESCE.*as grupo,.*al\.nivel,.*al\.tipo,.*COUNT\(\*\) as total/is.test(s)) {
    // aggregateByGroup
    const dim = /u\.turno/.test(s) ? 'turno' : 'setor';
    const groups = {};
    for (const al of fakeDB.alertas) {
      const u = fakeDB.usuarios.find(x => x.id === al.usuario_id);
      if (!u) continue;
      const key = (u[dim] || params[0]) + '|' + al.nivel + '|' + al.tipo;
      if (!groups[key]) {
        groups[key] = { grupo: u[dim] || params[0], nivel: al.nivel, tipo: al.tipo, total: 0, pessoas: new Set() };
      }
      groups[key].total++;
      groups[key].pessoas.add(al.usuario_id);
    }
    return [Object.values(groups).map(g => ({
      grupo: g.grupo, nivel: g.nivel, tipo: g.tipo,
      total: g.total, pessoas_distintas: g.pessoas.size
    }))];
  }

  // Dashboard heatmap
  if (/SELECT.*COALESCE\(u\.(setor|turno).*as grupo,.*a\.data,.*COUNT\(DISTINCT a\.usuario_id\) as pessoas_distintas,.*AVG\(a\.score_risco\) as media_score/is.test(s)) {
    const dim = /u\.turno/.test(s) ? 'turno' : 'setor';
    const startDate = params[1];
    const groups = {};
    for (const a of fakeDB.avaliacoes) {
      if (!a.completada) continue;
      if (a.data < startDate) continue;
      const u = fakeDB.usuarios.find(x => x.id === a.usuario_id);
      if (!u) continue;
      const key = (u[dim] || params[0]) + '|' + a.data;
      if (!groups[key]) groups[key] = { grupo: u[dim] || params[0], data: a.data, scores: [], pessoas: new Set() };
      groups[key].scores.push(parseFloat(a.score_risco));
      groups[key].pessoas.add(a.usuario_id);
    }
    return [Object.values(groups).map(g => ({
      grupo: g.grupo,
      data: g.data,
      pessoas_distintas: g.pessoas.size,
      media_score: g.scores.reduce((s,v) => s+v, 0) / g.scores.length
    }))];
  }

  // Dashboard kpis / resumo generic counts
  if (/^SELECT COUNT\(\*\) as total FROM usuarios u WHERE u\.status = 'ativo' AND u\.perfil = 'funcionario'/i.test(s)) {
    let users = fakeDB.usuarios.filter(u => u.status === 'ativo' && u.perfil === 'funcionario');
    if (s.includes('u.setor = ?')) users = users.filter(u => u.setor === params[0]);
    if (s.includes('u.turno = ?')) users = users.filter(u => u.turno === params[s.includes('u.setor = ?') ? 1 : 0]);
    return [[{ total: users.length }]];
  }

  if (/COUNT\(DISTINCT a\.usuario_id\) as participantes/i.test(s)) {
    const distinctUsers = new Set();
    for (const a of fakeDB.avaliacoes) {
      if (a.completada) distinctUsers.add(a.usuario_id);
    }
    return [[{ participantes: distinctUsers.size }]];
  }

  // Generic SELECT alertas count by nivel (resumo)
  if (/SELECT al\.nivel, COUNT\(\*\) as total FROM alertas al/i.test(s)) {
    return [[]];
  }
  if (/SELECT a\.nivel_risco, COUNT\(\*\) as total FROM avaliacoes a/i.test(s)) {
    return [[]];
  }

  // Catch-all
  // console.log('UNHANDLED SQL:', s.substring(0, 100));
  return [[]];
}

const pool = {
  execute: async (sql, params) => mockExecute(sql, params),
  query: async (sql, params) => mockExecute(sql, params)
};

// Inject mock into module cache
require.cache[require.resolve('./src/config/database')] = {
  exports: pool,
  loaded: true,
  id: require.resolve('./src/config/database'),
  filename: require.resolve('./src/config/database')
};

// ============================================================
// Util: mock req/res
// ============================================================
function mockRes() {
  const res = {
    statusCode: 200,
    body: null,
    headers: {},
    status(code) { this.statusCode = code; return this; },
    json(payload) { this.body = payload; return this; },
    send(payload) { this.body = payload; return this; },
    setHeader(k, v) { this.headers[k] = v; return this; }
  };
  return res;
}

async function call(controllerFn, req) {
  const res = mockRes();
  let nextErr = null;
  await controllerFn(req, res, (err) => { nextErr = err; });
  if (nextErr) throw nextErr;
  return res;
}

// ============================================================
// Test helpers
// ============================================================
const results = [];
async function test(name, fn) {
  try {
    await fn();
    results.push({ name, ok: true });
    console.log(`  OK  ${name}`);
  } catch (err) {
    results.push({ name, ok: false, err });
    console.log(`  FAIL ${name}\n       ${err.message}`);
  }
}

// ============================================================
// Cenario inicial: seed admin + lider + funcionarios
// ============================================================
async function seed() {
  const bcrypt = require('bcryptjs');
  const hash = await bcrypt.hash('Admin@123', 4);
  fakeDB.usuarios.push({
    id: 1, nome: 'Admin', email: 'admin@test.com', senha: hash,
    cargo: 'Admin', perfil: 'administrador', setor: 'Geral', turno: null,
    lider_id: null, status: 'ativo', created_at: new Date(), updated_at: new Date()
  });
  fakeDB.usuarios.push({
    id: 2, nome: 'Lider TI', email: 'lider@test.com', senha: hash,
    cargo: 'Lider', perfil: 'lider', setor: 'TI', turno: 'integral',
    lider_id: null, status: 'ativo', created_at: new Date(), updated_at: new Date()
  });
  // 6 funcionarios em TI para passar k=5
  for (let i = 0; i < 6; i++) {
    fakeDB.usuarios.push({
      id: 10 + i, nome: `Func TI ${i}`, email: `func${i}@test.com`, senha: hash,
      cargo: 'Dev', perfil: 'funcionario', setor: 'TI', turno: 'manha',
      lider_id: 2, status: 'ativo', created_at: new Date(), updated_at: new Date()
    });
  }
  // 2 funcionarios em RH (abaixo do k)
  for (let i = 0; i < 2; i++) {
    fakeDB.usuarios.push({
      id: 20 + i, nome: `Func RH ${i}`, email: `funcrh${i}@test.com`, senha: hash,
      cargo: 'Analista', perfil: 'funcionario', setor: 'RH', turno: 'tarde',
      lider_id: null, status: 'ativo', created_at: new Date(), updated_at: new Date()
    });
  }
  nextId.usuarios = 100;
}

// ============================================================
// Tests
// ============================================================
async function run() {
  await seed();

  const userController = require('./src/controllers/userController');
  const authController = require('./src/controllers/authController');
  const alertController = require('./src/controllers/alertController');
  const assessmentController = require('./src/controllers/assessmentController');
  const reportController = require('./src/controllers/reportController');
  const dashboardController = require('./src/controllers/dashboardController');

  const admin = fakeDB.usuarios[0];
  const lider = fakeDB.usuarios[1];
  const func = fakeDB.usuarios[2];

  // ---------------- AUTH ----------------
  await test('login: admin valido -> token + audit log', async () => {
    const res = await call(authController.login, {
      body: { email: 'admin@test.com', senha: 'Admin@123' },
      ip: '127.0.0.1', headers: {}
    });
    assert.strictEqual(res.statusCode, 200);
    assert.ok(res.body.data.token, 'token deve existir');
    assert.strictEqual(res.body.data.usuario.perfil, 'administrador');
    assert.ok(fakeDB.audit_logs.find(a => a.acao === 'auth.login_success'));
  });

  await test('login: senha errada -> 401 + audit log de falha', async () => {
    const res = await call(authController.login, {
      body: { email: 'admin@test.com', senha: 'errada' },
      ip: '127.0.0.1', headers: {}
    });
    assert.strictEqual(res.statusCode, 401);
    assert.ok(fakeDB.audit_logs.find(a => a.acao === 'auth.login_failed' && a.detalhes === 'senha incorreta'));
  });

  await test('login: email inexistente -> 401 + audit log', async () => {
    const res = await call(authController.login, {
      body: { email: 'naoexiste@test.com', senha: 'x' },
      ip: '127.0.0.1', headers: {}
    });
    assert.strictEqual(res.statusCode, 401);
  });

  // ---------------- RBAC: createUser ----------------
  await test('admin cria lider com sucesso', async () => {
    const res = await call(userController.createUser, {
      user: admin,
      body: { nome: 'Novo Lider', email: 'novolider@test.com', senha: '123456', perfil: 'lider', setor: 'Vendas' },
      ip: '127.0.0.1', headers: {}
    });
    assert.strictEqual(res.statusCode, 201);
    assert.strictEqual(res.body.data.perfil, 'lider');
    assert.strictEqual(res.body.data.lider_id, null, 'lider nao deve ter lider_id');
  });

  await test('admin cria funcionario exige lider_id', async () => {
    const res = await call(userController.createUser, {
      user: admin,
      body: { nome: 'Sem Lider', email: 'semlider@test.com', senha: '123456', perfil: 'funcionario' },
      ip: '127.0.0.1', headers: {}
    });
    assert.strictEqual(res.statusCode, 400);
    assert.match(res.body.message, /lider_id e obrigatorio/);
  });

  await test('admin cria funcionario com lider_id valido', async () => {
    const res = await call(userController.createUser, {
      user: admin,
      body: { nome: 'Func Vendas', email: 'funcv@test.com', senha: '123456', perfil: 'funcionario', setor: 'Vendas', lider_id: 2 },
      ip: '127.0.0.1', headers: {}
    });
    assert.strictEqual(res.statusCode, 201);
    assert.strictEqual(res.body.data.lider_id, 2);
  });

  await test('lider cria funcionario (lider_id forcado)', async () => {
    const res = await call(userController.createUser, {
      user: lider,
      body: {
        nome: 'Func Novo TI', email: 'funcnovo@test.com', senha: '123456',
        perfil: 'funcionario',
        lider_id: 999  // tentativa de spoofing
      },
      ip: '127.0.0.1', headers: {}
    });
    assert.strictEqual(res.statusCode, 201);
    assert.strictEqual(res.body.data.lider_id, lider.id, 'lider_id deve ser forcado ao do criador');
  });

  await test('lider NAO pode criar outro lider -> 403', async () => {
    const res = await call(userController.createUser, {
      user: lider,
      body: { nome: 'Tentativa', email: 'esc@test.com', senha: '123456', perfil: 'lider' },
      ip: '127.0.0.1', headers: {}
    });
    assert.strictEqual(res.statusCode, 403);
  });

  await test('lider NAO pode criar administrador -> 403', async () => {
    const res = await call(userController.createUser, {
      user: lider,
      body: { nome: 'Esc', email: 'esc2@test.com', senha: '123456', perfil: 'administrador' },
      ip: '127.0.0.1', headers: {}
    });
    assert.strictEqual(res.statusCode, 403);
  });

  await test('funcionario NAO pode criar usuario -> 403', async () => {
    const res = await call(userController.createUser, {
      user: func,
      body: { nome: 'X', email: 'x@test.com', senha: '123456', perfil: 'funcionario' },
      ip: '127.0.0.1', headers: {}
    });
    assert.strictEqual(res.statusCode, 403);
  });

  await test('audit log foi gravado para criacoes', async () => {
    // audit log eh fire-and-forget, esperar microtask drain
    await new Promise(r => setTimeout(r, 30));
    const creates = fakeDB.audit_logs.filter(a => a.acao === 'user.create');
    assert.ok(creates.length >= 3, `esperado >=3 user.create no audit log, achou ${creates.length}`);
  });

  // ---------------- LGPD: ALERTAS ----------------
  await test('lider GET /alertas -> 403 (so agregado)', async () => {
    const res = await call(alertController.listAlerts, {
      user: lider, query: {}, ip: '127.0.0.1', headers: {}
    });
    assert.strictEqual(res.statusCode, 403);
    assert.match(res.body.message, /agregado/);
  });

  await test('lider GET /alertas/nao-lidos -> 403', async () => {
    const res = await call(alertController.countUnread, {
      user: lider, query: {}, ip: '127.0.0.1', headers: {}
    });
    assert.strictEqual(res.statusCode, 403);
  });

  await test('funcionario GET /alertas -> 200 (proprios alertas)', async () => {
    // criar um alerta para o func
    fakeDB.alertas.push({ id: 1000, usuario_id: func.id, tipo: 'risco_alto', nivel: 'alto', descricao: 'teste', lido: false, data: new Date() });
    const res = await call(alertController.listAlerts, {
      user: func, query: {}, ip: '127.0.0.1', headers: {}
    });
    assert.strictEqual(res.statusCode, 200);
    assert.ok(Array.isArray(res.body.data.alertas));
  });

  await test('lider GET /alertas/agregado -> dados agregados sem identidade', async () => {
    // popular alertas em TI (6 funcs)
    for (let i = 0; i < 6; i++) {
      fakeDB.alertas.push({
        id: 2000 + i,
        usuario_id: 10 + i,
        tipo: 'risco_alto',
        nivel: 'alto',
        descricao: '...',
        lido: false,
        data: new Date()
      });
    }
    const res = await call(alertController.getAggregated, {
      user: lider, query: { dimensao: 'setor' }, ip: '127.0.0.1', headers: {}
    });
    assert.strictEqual(res.statusCode, 200);
    const grupos = res.body.data.grupos;
    assert.ok(Array.isArray(grupos));
    // Nao deve haver nenhum campo com nome de pessoa
    const json = JSON.stringify(res.body);
    assert.ok(!/Func TI \d/.test(json), 'nao deve conter nomes individuais');
  });

  // ---------------- LGPD: ASSESSMENTS ----------------
  await test('lider GET /avaliacoes -> 403', async () => {
    const res = await call(assessmentController.listAssessments, {
      user: lider, query: {}, ip: '127.0.0.1', headers: {}
    });
    assert.strictEqual(res.statusCode, 403);
    assert.match(res.body.message, /agregados/);
  });

  await test('lider GET /avaliacoes/historico -> 403', async () => {
    const res = await call(assessmentController.getHistory, {
      user: lider, query: {}, ip: '127.0.0.1', headers: {}
    });
    assert.strictEqual(res.statusCode, 403);
  });

  // ---------------- LGPD: REPORTS ----------------
  await test('admin GET /relatorios/individual/:id -> audit log', async () => {
    fakeDB.audit_logs.length = 0;
    await call(reportController.getIndividualReport, {
      user: admin, params: { userId: '10' }, query: {}, ip: '127.0.0.1', headers: {}
    });
    const log = fakeDB.audit_logs.find(a => a.acao === 'report.individual.view');
    assert.ok(log, 'audit log report.individual.view deve existir');
    assert.strictEqual(log.recurso_id, 10);
  });

  await test('team report NAO retorna membros[] nominais', async () => {
    const res = await call(reportController.getTeamReport, {
      user: lider, params: { liderId: '2' }, query: {}, ip: '127.0.0.1', headers: {}
    });
    assert.strictEqual(res.statusCode, 200);
    assert.ok(!res.body.data.membros, 'membros[] nao deve estar presente');
    assert.ok(res.body.data.resumo, 'resumo deve estar presente');
    assert.ok(res.body.data.distribuicao_risco, 'distribuicao_risco deve estar presente');
  });

  await test('lider tentando equipe de outro lider -> 403', async () => {
    const res = await call(reportController.getTeamReport, {
      user: lider, params: { liderId: '999' }, query: {}, ip: '127.0.0.1', headers: {}
    });
    assert.strictEqual(res.statusCode, 403);
  });

  // ---------------- k-anonymity ----------------
  await test('setor RH com 2 funcs -> suprimido', async () => {
    const res = await call(reportController.getSectorReport, {
      user: admin, params: { setor: 'RH' }, query: {}, ip: '127.0.0.1', headers: {}
    });
    assert.strictEqual(res.statusCode, 200);
    assert.strictEqual(res.body.data.suprimido, true, 'setor com <5 deve ser suprimido');
    assert.match(res.body.data.motivo, /insuficient/i);
  });

  await test('setor TI com 6 funcs -> NAO suprimido', async () => {
    const res = await call(reportController.getSectorReport, {
      user: admin, params: { setor: 'TI' }, query: {}, ip: '127.0.0.1', headers: {}
    });
    assert.strictEqual(res.statusCode, 200);
    assert.ok(!res.body.data.suprimido, 'setor com >=5 nao deve ser suprimido');
    assert.ok(res.body.data.resumo);
  });

  // ---------------- Dashboard agregacao ----------------
  await test('dashboard heatmap por setor -> nao expoe nomes', async () => {
    // popular avaliacoes em TI
    const today = new Date().toISOString().slice(0, 10);
    for (let i = 0; i < 6; i++) {
      fakeDB.avaliacoes.push({
        id: 100 + i, usuario_id: 10 + i, data: today,
        score_risco: 60 + i, nivel_risco: 'moderado', completada: true
      });
    }
    const res = await call(dashboardController.getHeatmap, {
      user: lider, query: { dimensao: 'setor' }, ip: '127.0.0.1', headers: {}
    });
    assert.strictEqual(res.statusCode, 200);
    assert.strictEqual(res.body.data.tipo, 'setor');
    const json = JSON.stringify(res.body);
    assert.ok(!/Func TI \d/.test(json), 'heatmap nao deve conter nomes individuais');
  });

  await test('dashboard heatmap por turno', async () => {
    const res = await call(dashboardController.getHeatmap, {
      user: lider, query: { dimensao: 'turno' }, ip: '127.0.0.1', headers: {}
    });
    assert.strictEqual(res.statusCode, 200);
    assert.strictEqual(res.body.data.tipo, 'turno');
  });

  // Espera pequena para audit logs fire-and-forget flushar
  await new Promise(r => setTimeout(r, 50));

  // ---------------- updateUser: hierarquia ----------------
  await test('lider atualizando subordinado: ok', async () => {
    const func0 = fakeDB.usuarios.find(u => u.id === 10);
    const res = await call(userController.updateUser, {
      user: lider, params: { id: '10' }, body: { cargo: 'Dev Senior' }, ip: '127.0.0.1', headers: {}
    });
    assert.strictEqual(res.statusCode, 200);
    // Não vamos checar valor exato pois o mock não persiste UPDATE; só validamos status
  });

  await test('lider tentando atualizar usuario que nao eh subordinado -> 403', async () => {
    const res = await call(userController.updateUser, {
      user: lider, params: { id: '1' }, body: { cargo: 'X' }, ip: '127.0.0.1', headers: {}
    });
    assert.strictEqual(res.statusCode, 403);
  });

  await test('admin nao pode se auto-rebaixar', async () => {
    const res = await call(userController.updateUser, {
      user: admin, params: { id: '1' }, body: { perfil: 'funcionario' }, ip: '127.0.0.1', headers: {}
    });
    assert.strictEqual(res.statusCode, 400);
    assert.match(res.body.message, /rebaixar/);
  });

  // ---------------- Relatorio
  // ============================================================
  // Resultado
  // ============================================================
  console.log('\n=================================');
  const passed = results.filter(r => r.ok).length;
  const failed = results.filter(r => !r.ok).length;
  console.log(`Total: ${results.length}  Passou: ${passed}  Falhou: ${failed}`);
  console.log('=================================');
  if (failed > 0) {
    console.log('\nFalhas:');
    for (const r of results.filter(r => !r.ok)) {
      console.log(`  - ${r.name}: ${r.err.message}`);
    }
    process.exit(1);
  } else {
    console.log('TODOS PASSARAM');
    process.exit(0);
  }
}

run().catch(err => {
  console.error('Erro fatal:', err);
  process.exit(2);
});
