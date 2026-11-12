-- Pedido direto: a Carolina Borges (carolina.borges@colegio-ramalhao.com)
-- fica também DT da turma 9.ºA, ao lado do Miguel Alain (já é o DT
-- principal — turmas.diretor_turma = 'Miguel Alain Branco'). Dois DT na
-- mesma turma, em simultâneo, sem alterar o DT principal nem o texto de
-- apresentação partilhado com o Scriptorium.
--
-- Execute no SQL Editor do Supabase, depois de db/add_turma_diretores.sql.
-- Seguro re-correr (ON CONFLICT DO NOTHING).

BEGIN;

INSERT INTO turma_diretores (turma_id, professor_id)
SELECT t.id, p.id
FROM turmas t
JOIN professores p ON lower(p.email) = lower('carolina.borges@colegio-ramalhao.com')
WHERE t.ano = 9 AND t.nome = 'A' AND t.diretor_turma = 'Miguel Alain Branco'
ON CONFLICT (turma_id, professor_id) DO NOTHING;

COMMIT;

-- Verificação — deve devolver uma linha (9, 'A', 'Miguel Alain Branco', 'Carolina Borges'):
--   SELECT t.ano, t.nome AS turma, t.diretor_turma AS dt_principal, p.nome AS dt_adicional
--   FROM turma_diretores td
--   JOIN turmas t ON t.id = td.turma_id
--   JOIN professores p ON p.id = td.professor_id
--   WHERE t.ano = 9 AND t.nome = 'A';
