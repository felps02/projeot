-- Psicossocial DB Schema (DDL idempotente)
-- Plataforma de avaliacao psicossocial para trabalhadores do comercio
-- Este arquivo cria a estrutura. Seeds ficam em seeds.sql.

CREATE DATABASE IF NOT EXISTS psicossocial_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE psicossocial_db;

-- ============================================================
-- Tabela de usuarios
-- ============================================================
CREATE TABLE IF NOT EXISTS usuarios (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nome VARCHAR(100) NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  senha VARCHAR(255) NOT NULL,
  cargo VARCHAR(100),
  perfil ENUM('administrador', 'lider', 'funcionario') DEFAULT 'funcionario',
  setor VARCHAR(100),
  turno ENUM('manha', 'tarde', 'noite', 'integral') NULL,
  lider_id INT NULL,
  status ENUM('ativo', 'inativo') DEFAULT 'ativo',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_usuarios_lider FOREIGN KEY (lider_id) REFERENCES usuarios(id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE INDEX idx_usuarios_email ON usuarios(email);
CREATE INDEX idx_usuarios_perfil ON usuarios(perfil);
CREATE INDEX idx_usuarios_setor ON usuarios(setor);
CREATE INDEX idx_usuarios_turno ON usuarios(turno);
CREATE INDEX idx_usuarios_lider_id ON usuarios(lider_id);
CREATE INDEX idx_usuarios_status ON usuarios(status);

-- ============================================================
-- Tabela de perguntas
-- ============================================================
CREATE TABLE IF NOT EXISTS perguntas (
  id INT AUTO_INCREMENT PRIMARY KEY,
  texto TEXT NOT NULL,
  categoria ENUM('estresse', 'burnout', 'ansiedade', 'sobrecarga', 'motivacao', 'assedio', 'exaustao', 'ambiente') NOT NULL,
  tipo ENUM('likert', 'emoji', 'selecao') NOT NULL DEFAULT 'likert',
  ativa BOOLEAN DEFAULT TRUE,
  ordem INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE INDEX idx_perguntas_categoria ON perguntas(categoria);
CREATE INDEX idx_perguntas_ativa ON perguntas(ativa);
CREATE INDEX idx_perguntas_ordem ON perguntas(ordem);

-- ============================================================
-- Tabela de avaliacoes
-- ============================================================
CREATE TABLE IF NOT EXISTS avaliacoes (
  id INT AUTO_INCREMENT PRIMARY KEY,
  usuario_id INT NOT NULL,
  data DATE NOT NULL,
  score_risco DECIMAL(5,2) DEFAULT 0.00,
  nivel_risco ENUM('baixo', 'moderado', 'alto', 'critico') DEFAULT 'baixo',
  completada BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_avaliacoes_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE INDEX idx_avaliacoes_usuario_id ON avaliacoes(usuario_id);
CREATE INDEX idx_avaliacoes_data ON avaliacoes(data);
CREATE INDEX idx_avaliacoes_nivel_risco ON avaliacoes(nivel_risco);
CREATE INDEX idx_avaliacoes_completada ON avaliacoes(completada);
CREATE UNIQUE INDEX idx_avaliacoes_usuario_data ON avaliacoes(usuario_id, data);

-- ============================================================
-- Tabela de respostas
-- ============================================================
CREATE TABLE IF NOT EXISTS respostas (
  id INT AUTO_INCREMENT PRIMARY KEY,
  avaliacao_id INT NOT NULL,
  pergunta_id INT NOT NULL,
  valor INT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_respostas_avaliacao FOREIGN KEY (avaliacao_id) REFERENCES avaliacoes(id) ON DELETE CASCADE,
  CONSTRAINT fk_respostas_pergunta FOREIGN KEY (pergunta_id) REFERENCES perguntas(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE INDEX idx_respostas_avaliacao_id ON respostas(avaliacao_id);
CREATE INDEX idx_respostas_pergunta_id ON respostas(pergunta_id);

-- ============================================================
-- Tabela de alertas
-- ============================================================
CREATE TABLE IF NOT EXISTS alertas (
  id INT AUTO_INCREMENT PRIMARY KEY,
  usuario_id INT NOT NULL,
  tipo ENUM('risco_alto', 'padrao_emocional', 'sem_checkin', 'emergencia') NOT NULL,
  nivel ENUM('baixo', 'moderado', 'alto', 'critico') NOT NULL DEFAULT 'alto',
  descricao TEXT,
  lido BOOLEAN DEFAULT FALSE,
  data TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_alertas_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE INDEX idx_alertas_usuario_id ON alertas(usuario_id);
CREATE INDEX idx_alertas_tipo ON alertas(tipo);
CREATE INDEX idx_alertas_nivel ON alertas(nivel);
CREATE INDEX idx_alertas_lido ON alertas(lido);
CREATE INDEX idx_alertas_data ON alertas(data);

-- ============================================================
-- Tabela de emergencias
-- ============================================================
CREATE TABLE IF NOT EXISTS emergencias (
  id INT AUTO_INCREMENT PRIMARY KEY,
  usuario_id INT NOT NULL,
  motivo VARCHAR(255) NOT NULL,
  descricao TEXT,
  status ENUM('aberta', 'em_atendimento', 'resolvida') DEFAULT 'aberta',
  prioridade ENUM('alta', 'critica') DEFAULT 'critica',
  data TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_emergencias_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE INDEX idx_emergencias_usuario_id ON emergencias(usuario_id);
CREATE INDEX idx_emergencias_status ON emergencias(status);
CREATE INDEX idx_emergencias_prioridade ON emergencias(prioridade);
CREATE INDEX idx_emergencias_data ON emergencias(data);

-- ============================================================
-- Tabela de audit logs
-- ============================================================
CREATE TABLE IF NOT EXISTS audit_logs (
  id INT AUTO_INCREMENT PRIMARY KEY,
  usuario_id INT,
  acao VARCHAR(100) NOT NULL,
  recurso VARCHAR(100) NULL,
  recurso_id INT NULL,
  detalhes TEXT,
  ip VARCHAR(45),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_audit_logs_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE INDEX idx_audit_logs_usuario_id ON audit_logs(usuario_id);
CREATE INDEX idx_audit_logs_acao ON audit_logs(acao);
CREATE INDEX idx_audit_logs_recurso ON audit_logs(recurso);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at);
