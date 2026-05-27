# Refatoração: cadastro, RBAC e LGPD

Histórico das alterações realizadas no backend. Cada bloco corresponde a um dos itens do brief original.

## Como rodar

1. Garanta que o MySQL esteja rodando localmente (ou ajuste `DB_HOST/PORT` no `.env`).
2. Copie `.env.example` para `.env` e ajuste credenciais (em especial `ADMIN_EMAIL`, `ADMIN_SENHA`, `JWT_SECRET`).
3. `npm install`
4. `npm run dev`

Não é necessário rodar `schema.sql` manualmente. O `initDb.js` cria o banco, executa o schema e popula o seed do admin na primeira inicialização.

Credenciais padrão do admin (se `ADMIN_SENHA` não for definida no `.env`):
- email: `admin@psicossocial.local`
- senha: `Admin@123` *(trocar em produção!)*

---

## Bloco A — Bootstrap do banco + seed do admin

| Arquivo | Mudança |
| --- | --- |
| `src/config/initDb.js` | **Novo.** Conecta no MySQL sem `database`, executa `schema.sql`, aplica migrations idempotentes (colunas `turno`, `recurso`, `recurso_id`), executa `seeds.sql` se vazio e cria o admin inicial. |
| `database/schema.sql` | DDL idempotente apenas (sem INSERTs). Adicionada coluna `turno` em `usuarios` e colunas `recurso/recurso_id` em `audit_logs`. |
| `database/seeds.sql` | **Novo.** Perguntas iniciais, executado somente se a tabela estiver vazia. |
| `src/app.js` | Chama `initDb()` antes de `app.listen`. Em falha, derruba o processo com log estruturado. |

**Resultado:** o "Erro interno do servidor" no cadastro era causado pelo banco não existir. Com o bootstrap, basta dar `npm run dev` e o banco/tabelas/admin sobem automaticamente.

---

## Bloco B — RBAC hierárquico de cadastro

Hierarquia: **ADMIN → cria LÍDER → cria FUNCIONÁRIO**. Funcionário não cria ninguém.

| Arquivo | Mudança |
| --- | --- |
| `src/routes/auth.js` | **Removido `POST /auth/register`**. Resta `/login` e `/me`. |
| `src/controllers/authController.js` | Função `register` removida. `login` agora grava `audit_log` (sucesso e tentativas falhas). |
| `src/controllers/userController.js` | **Novo `createUser`** com a hierarquia: admin cria líder/funcionário (exige `lider_id` válido para funcionário); líder cria apenas funcionário e o backend **força** `lider_id = req.user.id` ignorando o body. `updateUser` refeito para impedir auto-promoção e escalonamentos. `deleteUser` impede desativar último admin ou desativar a si mesmo. |
| `src/routes/users.js` | Adicionado `POST /usuarios` com `authorize(['administrador','lider'])`. |
| `src/middleware/validator.js` | `registerValidation` → `createUserValidation`. Inclui validação de `turno`. |
| `src/models/User.js` | `create`/`update`/SELECTs incluem `turno`. Novo `isValidLeader(id)` para validar `lider_id` na criação. Novo `countByPerfil` para a regra do último admin. |

**Endpoints relevantes:**

```
POST   /api/v1/auth/login            público
GET    /api/v1/auth/me               autenticado
POST   /api/v1/usuarios              admin (lider|funcionario|administrador) | líder (funcionario, lider_id forçado)
GET    /api/v1/usuarios              admin (todos) | líder (apenas subordinados)
GET    /api/v1/usuarios/:id          admin | líder se subordinado | próprio
PUT    /api/v1/usuarios/:id          admin (todos os campos) | líder (subordinado, campos limitados) | próprio (subset)
DELETE /api/v1/usuarios/:id          admin
```

---

## Bloco C — LGPD / privacidade nas visualizações

Regra geral: **líder enxerga apenas dados agregados por setor/turno**, com k-anonymity (`K_ANONYMITY_MIN=5` por padrão, configurável no `.env`). Dados individuais são restritos ao próprio usuário e ao administrador (com audit log).

### Utilitário de privacidade

`src/utils/privacy.js` — funções `shouldSuppress(count)`, `suppressedGroup(extras)` e constante `K_MIN`. Quando um grupo tem menos que `K_MIN` membros, o registro é substituído por `{ suprimido: true, motivo: "Dados insuficientes..." }`.

### Pontos de vazamento corrigidos

| Antes | Depois |
| --- | --- |
| `dashboard/heatmap` retornava `u.nome as grupo` para líderes (score por pessoa) | Sempre agrupa por **setor** ou **turno** (`?dimensao=turno`). |
| `dashboard/resumo` filtrava por `lider_id` (subordinados nominais) | Aceita `?setor=` e `?turno=` para escopo agregado. Sem filtro por `lider_id`. |
| `dashboard/tendencias`, `dashboard/kpis` | Idem — agregados, com k-anonymity por bucket. |
| `GET /alertas` para líder mostrava alertas nominais de subordinados | Líder recebe **403** em `/alertas` e `/alertas/nao-lidos`. Novo `GET /alertas/agregado?dimensao=setor` retorna contagem por grupo/nivel/tipo. |
| `Alert.findBySubordinates`, `countUnreadBySubordinates` | **Removidos.** Substituídos por `Alert.aggregateByGroup`. |
| `alertService.notifyLeader` criava alerta `"[Subordinado: Maria] ..."` no inbox do líder | Agora cria alerta `"[Anonimizado] Novo sinal em setor X..."`. Mantém disparo, esconde identidade. |
| `GET /relatorios/individual/:userId` aberto para líderes | **Apenas administrador.** Cada acesso grava `audit_log` (`report.individual.view`, `*.export_pdf`, `*.export_excel`). |
| `reportService.generateTeamReport` retornava `membros[]` com score por pessoa | Apenas agregados (`resumo`, `distribuicao_risco`, `categorias`). Aplica k-anonymity: se o time tem menos que `K_MIN` membros, devolve `{ suprimido: true }`. |
| `reportService.generateSectorReport` sem k-anonymity | Aplica `shouldSuppress` no total de funcionários do setor. |
| `assessmentController.listAssessments` para líder usava `Assessment.getBySubordinates` | Líder recebe **403**. Admin pode consultar individual via `?usuario_id=` (gera audit log). |
| `assessmentController.getAssessment` permitia líder ver assessment de subordinado | Apenas próprio usuário ou admin (com audit log). |
| `assessmentController.getHistory` para líder | **403.** Admin pode `?usuario_id=` (audit log). |

### Audit log (`audit_logs`)

Eventos registrados:

- `auth.login_success`, `auth.login_failed`
- `user.create`, `user.update`, `user.delete`, `user.view`
- `assessment.list_individual`, `assessment.view_individual`, `assessment.view_history`
- `report.individual.view`, `report.individual.export_pdf`, `report.individual.export_excel`

Campos: `usuario_id` (quem fez), `acao`, `recurso`, `recurso_id`, `detalhes`, `ip`, `created_at`.

---

## Bloco D — Tratamento de erros e logger

| Arquivo | Mudança |
| --- | --- |
| `src/middleware/errorHandler.js` | Mapeia códigos do MySQL: `ER_BAD_DB_ERROR`, `ER_ACCESS_DENIED_ERROR`, `ER_NO_SUCH_TABLE`, `ECONNREFUSED`, `PROTOCOL_CONNECTION_LOST`, `ETIMEDOUT`. Em ambiente `!production`, anexa `debug` com `code` e `message` originais à resposta. Log estruturado de toda exceção. |
| `src/utils/logger.js` | Logger leve (sem dependência nova) com níveis `error/warn/info/debug`, controlado por `LOG_LEVEL`. Saída em JSON. |
| `src/models/AuditLog.js` | Novo. Método estático `AuditLog.log(req, { acao, recurso, recurso_id, detalhes })` extrai automaticamente `user_id` e `ip`. Falhas no log não derrubam a requisição. |

---

## Bloco E — Schema: coluna `turno`

| Coluna | Tipo | Tabela |
| --- | --- | --- |
| `turno` | `ENUM('manha','tarde','noite','integral')` NULL | `usuarios` |
| `recurso` | `VARCHAR(100)` NULL | `audit_logs` |
| `recurso_id` | `INT` NULL | `audit_logs` |

O `initDb.js` adiciona essas colunas via `ALTER TABLE` se elas não existirem — seguro rodar várias vezes.

---

## Variáveis de ambiente novas/alteradas

```
ADMIN_EMAIL=admin@psicossocial.local
ADMIN_NOME=Administrador
ADMIN_SENHA=Admin@123        # troque em producao!
LOG_LEVEL=info               # error | warn | info | debug
CORS_ORIGINS=*               # ou lista CSV: https://app.exemplo.com,https://outro.com
K_ANONYMITY_MIN=5            # mínimo de pessoas para mostrar agregado
NODE_ENV=development         # use production para esconder stacks
```

---

## Checklist de validação manual

```
[ ] npm run dev sobe sem erro, log mostra "Banco psicossocial_db pronto"
[ ] log mostra "Administrador criado: admin@psicossocial.local"
[ ] POST /api/v1/auth/login com admin retorna token
[ ] POST /api/v1/usuarios autenticado como admin cria líder (perfil: lider) com sucesso
[ ] POST /api/v1/usuarios autenticado como líder cria funcionário (lider_id auto)
[ ] POST /api/v1/usuarios autenticado como funcionário retorna 403
[ ] GET /api/v1/dashboard/heatmap?dimensao=setor agrupa por setor, sem nomes
[ ] GET /api/v1/dashboard/heatmap?dimensao=turno agrupa por turno
[ ] GET /api/v1/alertas como líder retorna 403
[ ] GET /api/v1/alertas/agregado como líder retorna agregado
[ ] GET /api/v1/relatorios/individual/X como líder retorna 403
[ ] GET /api/v1/relatorios/equipe/X retorna apenas resumo (sem membros[])
[ ] Setor com < 5 funcionários retorna { suprimido: true }
[ ] audit_logs registra eventos
```

---

## Não foi feito (por escopo)

- Não há testes automatizados — adicionar Jest/supertest com fixtures (em particular para os fluxos de RBAC e LGPD) seria o próximo passo.
- O `swagger.json` ainda descreve `/auth/register` e respostas antigas. Atualizar a especificação OpenAPI manualmente ou via geração automática.
- Frontend Flutter (`frontend/`) não foi tocado. As mudanças de API que **podem quebrar o cliente** são: ausência de `/auth/register`, novo `POST /usuarios`, 403 em `/alertas` e `/alertas/nao-lidos` para líder, `membros[]` removido do team report.
