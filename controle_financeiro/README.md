# Controle Financeiro Pessoal

Aplicativo Flutter de controle financeiro pessoal com persistência local em SQLite usando o ORM **Floor**. Permite cadastrar receitas e despesas, organizá-las por categoria, filtrar a lista e visualizar o saldo total calculado em tempo real.

> Atividade Prática — Desenvolvimento Mobile

## Funcionalidades

- Cadastro, edição e exclusão de lançamentos (CRUD completo)
- Organização por categoria (Alimentação, Transporte, Salário, Lazer, Moradia)
- Tipos: **receita** e **despesa**
- Lista reativa com `StreamBuilder` — atualiza sozinha ao salvar/excluir
- Filtro por tipo: Todos / Receitas / Despesas (`DropdownButton`)
- Confirmação de exclusão via `AlertDialog`
- Cálculo do saldo total via `rawQuery` com `SUM` + `CASE WHEN`
- Foreign Keys ativadas (`PRAGMA foreign_keys = ON`)

## Arquitetura

```
lib/
├── entities/         # @Entity (Categoria, Lancamento)
├── dao/              # @dao (CategoriaDao, LancamentoDao)
├── database/         # @Database + .g.dart gerado
├── repository/       # Camada que isola DAOs da UI
├── widgets/          # Componentes reutilizáveis (SaldoCard)
├── screens/          # Telas (HomeScreen, LancamentoFormScreen)
└── main.dart         # Bootstrap do app
```

A UI **nunca** acessa o DAO diretamente — sempre passa pelo `LancamentoRepository` / `CategoriaRepository`.


## Como executar

1. Instale as dependências:
   ```bash
   flutter pub get
   ```
2. (Opcional) Regere o `app_database.g.dart` com:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
   > **Observação:** Este projeto já contém um `app_database.g.dart` escrito manualmente, equivalente ao que o `floor_generator` produziria. Isso foi necessário porque a versão atual do `floor_generator` (1.5.0) usa um `analyzer` antigo que não suporta a sintaxe do Dart SDK 3.11 instalado nesta máquina. O arquivo segue exatamente o padrão gerado pelo Floor (mesmos `InsertionAdapter`, `UpdateAdapter`, `DeletionAdapter`, `QueryAdapter`).
3. Rode o app:
   ```bash
   flutter run
   ```

## Cálculo de saldo (rawQuery)

Implementado em `lib/repository/lancamento_repository.dart`:

```dart
final result = await db.database.rawQuery('''
  SELECT
    SUM(CASE WHEN tipo = 'receita' THEN valor ELSE 0 END) AS total_receitas,
    SUM(CASE WHEN tipo = 'despesa' THEN valor ELSE 0 END) AS total_despesas
  FROM Lancamento
''');
```

## Inspecionar o banco

- **DB Browser for SQLite** abre o arquivo `.db` diretamente
- Para extrair do emulador Android:
  Android Studio → Device Explorer → `data/data/com.faculdade.controle_financeiro/databases/controle_financeiro.db`

## Dependências principais

| Pacote          | Versão  | Função                                     |
|-----------------|---------|--------------------------------------------|
| floor           | ^1.4.0  | ORM (runtime + anotações)                  |
| sqflite         | ^2.3.0  | Driver SQLite                              |
| path            | ^1.9.0  | Resolução do caminho do banco              |
| intl            | ^0.19.0 | Formatação de moeda BR / datas             |
| floor_generator | ^1.4.0  | Code generator (dev)                       |
| build_runner    | ^2.4.0  | Runner do code generator (dev)             |

## Autor

JoaoVictor-1205 — Atividade Prática de Desenvolvimento Mobile
