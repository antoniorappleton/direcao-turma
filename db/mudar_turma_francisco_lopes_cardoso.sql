-- Pedido direto: muda o aluno Francisco Maria Correia de Campos Lopes
-- Cardoso do 10.ºB (DT: Concha Cal Reynolds De Sousa) para o 10.ºB1 (DT:
-- António Appleton) — uma mudança normal de turma. O aluno mantém o
-- mesmo id e toda a ficha; só a turma muda, e com ela o DT responsável.
--
-- Mesma lógica de db/add_mudar_turma_aluno.sql, mas como SQL direto em vez
-- de RPC: este script corre no SQL Editor do Supabase como
-- superutilizador, sem sessão de professor autenticado — a função
-- mudar_turma_aluno exige isso mesmo (fica para a app, a partir de agora,
-- usar nas próximas mudanças de turma).
--
-- Execute no SQL Editor do Supabase, depois de db/add_mudar_turma_aluno.sql
-- (garante a coluna matriculas.observacoes e o ano letivo ativo usados
-- abaixo).

BEGIN;

UPDATE matriculas
SET data_fim = current_date, estado = 'transferida'
WHERE estado = 'ativa' AND data_fim IS NULL
  AND aluno_id = (
    SELECT id FROM alunos WHERE nome = 'Francisco Maria Correia de Campos Lopes Cardoso'
  );

INSERT INTO matriculas (aluno_id, turma_id, ano_letivo_id, data_inicio, estado, observacoes)
SELECT
  a.id,
  t.id,
  (SELECT id FROM anos_letivos WHERE ativo = true LIMIT 1),
  current_date,
  'ativa',
  'Mudança de turma (10.ºB → 10.ºB1).'
FROM alunos a, turmas t
WHERE a.nome = 'Francisco Maria Correia de Campos Lopes Cardoso'
  AND t.ano = 10 AND t.nome = 'B1';

UPDATE alunos
SET turma_id = (SELECT id FROM turmas WHERE ano = 10 AND nome = 'B1')
WHERE nome = 'Francisco Maria Correia de Campos Lopes Cardoso';

COMMIT;

-- Verificação — deve devolver ('Francisco Maria Correia de Campos Lopes
-- Cardoso', 'B1', 10, 'António Maria Rivotti Maggiorani Appleton'):
--   SELECT a.nome, t.nome AS turma, t.ano, t.diretor_turma
--   FROM alunos a JOIN turmas t ON t.id = a.turma_id
--   WHERE a.nome = 'Francisco Maria Correia de Campos Lopes Cardoso';
