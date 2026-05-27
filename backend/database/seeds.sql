-- Seeds iniciais (apenas executados se a tabela perguntas estiver vazia)
-- Executado pelo initDb.js apos schema.sql

INSERT INTO perguntas (texto, categoria, tipo, ativa, ordem) VALUES
('Como voce avalia seu nivel de estresse hoje no trabalho?', 'estresse', 'likert', TRUE, 1),
('Voce sentiu exaustao emocional durante sua jornada de trabalho?', 'burnout', 'likert', TRUE, 2),
('Em que medida voce se sentiu ansioso(a) durante o expediente?', 'ansiedade', 'likert', TRUE, 3),
('Voce considera que a carga de trabalho atual e adequada para voce?', 'sobrecarga', 'likert', TRUE, 4),
('Qual e seu nivel de motivacao para realizar suas atividades profissionais?', 'motivacao', 'likert', TRUE, 5),
('Voce se sentiu desrespeitado(a) ou constrangido(a) no ambiente de trabalho?', 'assedio', 'likert', TRUE, 6),
('Como voce avalia seu nivel de energia e disposicao ao final do dia?', 'exaustao', 'emoji', TRUE, 7),
('Como voce classifica o clima organizacional do seu setor hoje?', 'ambiente', 'emoji', TRUE, 8),
('Voce conseguiu fazer pausas adequadas durante seu turno?', 'sobrecarga', 'likert', TRUE, 9),
('Voce sente que recebe apoio suficiente da sua lideranca?', 'ambiente', 'likert', TRUE, 10);
