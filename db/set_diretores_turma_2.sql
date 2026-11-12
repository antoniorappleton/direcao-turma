-- Continuação de db/set_diretores_turma.sql: nessa altura só 8 das 30
-- turmas da lista tinham professor com conta já criada em `professores`
-- (as outras 22 ficaram sem `diretor_turma_id`, ver comentário desse
-- ficheiro). Desde então foram criadas mais contas — este ficheiro resolve
-- as que já têm professor correspondente, usando o email (mais estável do
-- que comparar por nome).
--
-- Motivo imediato: o Jorge Morais (jorge.morais@colegio-ramalhao.com) fez
-- login e o 6.ºA não lhe aparecia no Painel DT — porque `diretor_turma_id`
-- dessa turma continuava NULL, apesar de `diretor_turma` (texto) já dizer
-- 'Jorge Manuel Rodrigues Morais Varandas Fernandes'. Esta é a causa raiz
-- de qualquer DT que "não aparece": `turmas.diretor_turma_id` é a fonte de
-- verdade para o Painel DT (ver isDiretorDaTurma em permissions.js); o
-- texto em `diretor_turma` é só apresentação e já não conta para acessos.
--
-- Cada UPDATE confirma (ano, nome, diretor_turma) tal como no ficheiro
-- anterior — evita acertar em turmas duplicadas (ano, nome) de
-- ciclos/cursos diferentes — e só atua se diretor_turma_id ainda estiver
-- por preencher. Seguro re-correr.
--
-- Execute no SQL Editor do Supabase, depois de db/add_diretor_turma_id.sql.

BEGIN;

UPDATE turmas SET diretor_turma_id = (SELECT id FROM professores WHERE lower(email) = lower('mariana.sobral@colegio-ramalhao.com'))
  WHERE ano = 5 AND nome = 'A' AND diretor_turma = 'Mariana Pereira Alho Da Silva Ramalho Sobral' AND diretor_turma_id IS NULL;

UPDATE turmas SET diretor_turma_id = (SELECT id FROM professores WHERE lower(email) = lower('david.oliveira@colegio-ramalhao.com'))
  WHERE ano = 5 AND nome = 'B' AND diretor_turma = 'David Miguel Teixeira De Oliveira' AND diretor_turma_id IS NULL;

UPDATE turmas SET diretor_turma_id = (SELECT id FROM professores WHERE lower(email) = lower('sara.infante@colegio-ramalhao.com'))
  WHERE ano = 5 AND nome = 'C' AND diretor_turma = 'Sara Filipa Infante Gaspar Chambel Leitão' AND diretor_turma_id IS NULL;

UPDATE turmas SET diretor_turma_id = (SELECT id FROM professores WHERE lower(email) = lower('jorge.morais@colegio-ramalhao.com'))
  WHERE ano = 6 AND nome = 'A' AND diretor_turma = 'Jorge Manuel Rodrigues Morais Varandas Fernandes' AND diretor_turma_id IS NULL;

UPDATE turmas SET diretor_turma_id = (SELECT id FROM professores WHERE lower(email) = lower('margarida.marques@colegio-ramalhao.com'))
  WHERE ano = 6 AND nome = 'C' AND diretor_turma = 'Margarida Da Silva Marques' AND diretor_turma_id IS NULL;

UPDATE turmas SET diretor_turma_id = (SELECT id FROM professores WHERE lower(email) = lower('mariana.fontes@colegio-ramalhao.com'))
  WHERE ano = 7 AND nome = 'A' AND diretor_turma = 'Mariana Da Silva Fontes' AND diretor_turma_id IS NULL;

UPDATE turmas SET diretor_turma_id = (SELECT id FROM professores WHERE lower(email) = lower('rita.ribeiro@colegio-ramalhao.com'))
  WHERE ano = 8 AND nome = 'A' AND diretor_turma = 'Ana Rita Zuzarte Reis Gomes Nunes Ribeiro' AND diretor_turma_id IS NULL;

UPDATE turmas SET diretor_turma_id = (SELECT id FROM professores WHERE lower(email) = lower('joao.mariano@colegio-ramalhao.com'))
  WHERE ano = 8 AND nome = 'C' AND diretor_turma = 'João Francisco Dos Santos Neto Mariano' AND diretor_turma_id IS NULL;

UPDATE turmas SET diretor_turma_id = (SELECT id FROM professores WHERE lower(email) = lower('miguel.alain@colegio-ramalhao.com'))
  WHERE ano = 9 AND nome = 'A' AND diretor_turma = 'Miguel Alain Branco' AND diretor_turma_id IS NULL;

UPDATE turmas SET diretor_turma_id = (SELECT id FROM professores WHERE lower(email) = lower('joao.sobral@colegio-ramalhao.com'))
  WHERE ano = 9 AND nome = 'B' AND diretor_turma = 'João Pedro Marques Sobral' AND diretor_turma_id IS NULL;

UPDATE turmas SET diretor_turma_id = (SELECT id FROM professores WHERE lower(email) = lower('sara.lira@colegio-ramalhao.com'))
  WHERE ano = 10 AND nome = 'A' AND diretor_turma = 'Sara Raquel Lopes De Lira' AND diretor_turma_id IS NULL;

UPDATE turmas SET diretor_turma_id = (SELECT id FROM professores WHERE lower(email) = lower('concha.sousa@colegio-ramalhao.com'))
  WHERE ano = 10 AND nome = 'B' AND diretor_turma = 'Concha Cal Reynolds De Sousa' AND diretor_turma_id IS NULL;

UPDATE turmas SET diretor_turma_id = (SELECT id FROM professores WHERE lower(email) = lower('carlos.domingos@colegio-ramalhao.com'))
  WHERE ano = 10 AND nome = 'C' AND diretor_turma = 'Carlos Manuel Costa Domingos' AND diretor_turma_id IS NULL;

UPDATE turmas SET diretor_turma_id = (SELECT id FROM professores WHERE lower(email) = lower('ines.couceiro@colegio-ramalhao.com'))
  WHERE ano = 11 AND nome = 'B' AND diretor_turma = 'Inês Ribeiro Garcia De Paiva Couceiro' AND diretor_turma_id IS NULL;

UPDATE turmas SET diretor_turma_id = (SELECT id FROM professores WHERE lower(email) = lower('francisco.maia@colegio-ramalhao.com'))
  WHERE ano = 12 AND nome = 'A' AND diretor_turma = 'Francisco Salgado Machado De Oliveira E Maia' AND diretor_turma_id IS NULL;

UPDATE turmas SET diretor_turma_id = (SELECT id FROM professores WHERE lower(email) = lower('margarida.nobre@colegio-ramalhao.com'))
  WHERE ano = 12 AND nome = 'B' AND diretor_turma = 'Margarida Maria Dias Nobre Bábau' AND diretor_turma_id IS NULL;

COMMIT;

-- Ainda sem professor com conta criada (continua sem diretor_turma_id
-- depois deste ficheiro) — é preciso criar a conta primeiro, depois
-- voltar a correr este ficheiro (idempotente) ou atribuir à mão:
--   11.ºC — Susana Duarte de Santos Viola (nenhum professor com esse nome
--   em `professores` à data deste ficheiro).
--
-- Verificação geral — turmas ainda sem diretor_turma_id apesar de
-- diretor_turma (texto) preenchido:
--   SELECT ano, nome, diretor_turma FROM turmas
--   WHERE diretor_turma_id IS NULL AND diretor_turma IS NOT NULL
--   ORDER BY ano, nome;
