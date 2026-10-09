-- Atribuição explícita do Diretor de Turma (DT) de cada turma, via
-- turmas.diretor_turma_id (FK para professores) — ver
-- db/add_diretor_turma_id.sql, que tem de ter corrido primeiro (cria a
-- coluna e substitui is_current_user_dt_da_turma para passar a usá-la).
--
-- Lista fornecida pelo utilizador (mesma fonte que já tinha populado
-- turmas.diretor_turma em texto — ver Scriptorium/db/add_diretor_turma.sql).
--
-- Cada UPDATE identifica a turma por (ano, nome, diretor_turma) — o texto
-- já existente entra na condição, não só ano+nome, porque há pares
-- (ano, nome) duplicados entre ciclos/cursos diferentes (ex: duas turmas
-- "12º A" com ciclo_id distinto, só uma delas com DT). Sem o texto na
-- condição, o UPDATE por (ano, nome) acertaria nas duas de uma vez.
--
-- O professor é resolvido pelo nome em professores.nome via subquery:
--   - se não houver nenhum professor com esse nome, a subquery devolve NULL
--     (fica por atribuir, sem erro) — ver verificação no fim do ficheiro;
--   - se houver mais do que um professor com o mesmo nome, a subquery
--     devolve mais de uma linha e o UPDATE falha com erro, travando logo
--     (nada fica a meio) em vez de atribuir o DT errado.
--
-- IMPORTANTE: professores.nome guarda hoje nome curto (primeiro nome +
-- último apelido), não o nome legal completo de turmas.diretor_turma — por
-- isso 7 dos UPDATEs abaixo usam o nome curto (confirmado por conta/email
-- existente), não o texto completo de diretor_turma:
--   Maria Da Luz Tinoco Alpoim Barbosa      -> Luz Barbosa
--   Fernando Tiago Rosa Franco Frazão
--     Marques Da Silva                      -> Fernando Silva
--   Diogo Nuno Martins De Brito Alves
--     Moreira                               -> Diogo Moreira
--   Xavier Calvão Mestre                    -> Xavier Mestre
--   Sofia Silva Lopes Nogueira Cabral
--     Antunes Oliveira                      -> Sofia Oliveira
--   David Amaro Pereira Teixeira            -> David Teixeira
--   Carla Alexandra dos Reis da Silva
--     Saldanha                              -> Carla Saldanha
-- (há dois "David" na lista original — "David Amaro Pereira Teixeira" e
-- "David Miguel Teixeira De Oliveira" — só o primeiro tem conta, por isso
-- "David Teixeira" só pode ser esse; o segundo fica sem conta, como os
-- restantes 15 nomes abaixo, que ainda não têm professor criado.)
--
-- Das 30 turmas desta lista, só 8 têm professor com conta já criada (os 7
-- acima + António, que já usa o nome completo). As outras 22 ficam sem
-- diretor_turma_id até essas contas serem criadas — nessa altura, basta
-- voltar a correr este ficheiro (é idempotente).
--
-- Turmas que não aparecem aqui ficam sem diretor_turma_id: continuam
-- acessíveis a quem as selecionar em "as minhas turmas" (professor_turmas),
-- só sem o papel de DT — um professor pode continuar a dar aulas nelas sem
-- ser o DT.
--
-- Execute no SQL Editor do Supabase, depois de db/add_diretor_turma_id.sql.
-- Seguro re-correr.

BEGIN;

UPDATE turmas SET diretor_turma_id = (SELECT id FROM professores WHERE nome = 'João Pedro Marques Sobral') WHERE ano = 9 AND nome = 'B' AND diretor_turma = 'João Pedro Marques Sobral';
UPDATE turmas SET diretor_turma_id = (SELECT id FROM professores WHERE nome = 'Carolina Antunes Borges') WHERE ano = 9 AND nome = 'A' AND diretor_turma = 'Carolina Antunes Borges';
UPDATE turmas SET diretor_turma_id = (SELECT id FROM professores WHERE nome = 'Luz Barbosa') WHERE ano = 8 AND nome = 'B' AND diretor_turma = 'Maria Da Luz Tinoco Alpoim Barbosa';
UPDATE turmas SET diretor_turma_id = (SELECT id FROM professores WHERE nome = 'João Francisco Dos Santos Neto Mariano') WHERE ano = 8 AND nome = 'C' AND diretor_turma = 'João Francisco Dos Santos Neto Mariano';
UPDATE turmas SET diretor_turma_id = (SELECT id FROM professores WHERE nome = 'Ana Rita Zuzarte Reis Gomes Nunes Ribeiro') WHERE ano = 8 AND nome = 'A' AND diretor_turma = 'Ana Rita Zuzarte Reis Gomes Nunes Ribeiro';
UPDATE turmas SET diretor_turma_id = (SELECT id FROM professores WHERE nome = 'Mariana Da Silva Fontes') WHERE ano = 7 AND nome = 'A' AND diretor_turma = 'Mariana Da Silva Fontes';
UPDATE turmas SET diretor_turma_id = (SELECT id FROM professores WHERE nome = 'Fernando Silva') WHERE ano = 7 AND nome = 'B' AND diretor_turma = 'Fernando Tiago Rosa Franco Frazão Marques Da Silva';
UPDATE turmas SET diretor_turma_id = (SELECT id FROM professores WHERE nome = 'Diogo Moreira') WHERE ano = 7 AND nome = 'C' AND diretor_turma = 'Diogo Nuno Martins De Brito Alves Moreira';
UPDATE turmas SET diretor_turma_id = (SELECT id FROM professores WHERE nome = 'Margarida Da Silva Marques') WHERE ano = 6 AND nome = 'C' AND diretor_turma = 'Margarida Da Silva Marques';
UPDATE turmas SET diretor_turma_id = (SELECT id FROM professores WHERE nome = 'Jorge Manuel Rodrigues Morais Varandas Fernandes') WHERE ano = 6 AND nome = 'A' AND diretor_turma = 'Jorge Manuel Rodrigues Morais Varandas Fernandes';
UPDATE turmas SET diretor_turma_id = (SELECT id FROM professores WHERE nome = 'Xavier Mestre') WHERE ano = 6 AND nome = 'B' AND diretor_turma = 'Xavier Calvão Mestre';
UPDATE turmas SET diretor_turma_id = (SELECT id FROM professores WHERE nome = 'Sara Filipa Infante Gaspar Chambel Leitão') WHERE ano = 5 AND nome = 'C' AND diretor_turma = 'Sara Filipa Infante Gaspar Chambel Leitão';
UPDATE turmas SET diretor_turma_id = (SELECT id FROM professores WHERE nome = 'Mariana Pereira Alho Da Silva Ramalho Sobral') WHERE ano = 5 AND nome = 'A' AND diretor_turma = 'Mariana Pereira Alho Da Silva Ramalho Sobral';
UPDATE turmas SET diretor_turma_id = (SELECT id FROM professores WHERE nome = 'David Miguel Teixeira De Oliveira') WHERE ano = 5 AND nome = 'B' AND diretor_turma = 'David Miguel Teixeira De Oliveira';
UPDATE turmas SET diretor_turma_id = (SELECT id FROM professores WHERE nome = 'Sofia Oliveira') WHERE ano = 12 AND nome = 'A1' AND diretor_turma = 'Sofia Silva Lopes Nogueira Cabral Antunes Oliveira';
UPDATE turmas SET diretor_turma_id = (SELECT id FROM professores WHERE nome = 'Sofia Oliveira') WHERE ano = 12 AND nome = 'B1' AND diretor_turma = 'Sofia Silva Lopes Nogueira Cabral Antunes Oliveira';
UPDATE turmas SET diretor_turma_id = (SELECT id FROM professores WHERE nome = 'David Teixeira') WHERE ano = 11 AND nome = 'A1' AND diretor_turma = 'David Amaro Pereira Teixeira';
UPDATE turmas SET diretor_turma_id = (SELECT id FROM professores WHERE nome = 'David Teixeira') WHERE ano = 11 AND nome = 'B1' AND diretor_turma = 'David Amaro Pereira Teixeira';
UPDATE turmas SET diretor_turma_id = (SELECT id FROM professores WHERE nome = 'David Teixeira') WHERE ano = 11 AND nome = 'C1' AND diretor_turma = 'David Amaro Pereira Teixeira';
UPDATE turmas SET diretor_turma_id = (SELECT id FROM professores WHERE nome = 'António Maria Rivotti Maggiorani Appleton') WHERE ano = 10 AND nome = 'A1' AND diretor_turma = 'António Maria Rivotti Maggiorani Appleton';
UPDATE turmas SET diretor_turma_id = (SELECT id FROM professores WHERE nome = 'António Maria Rivotti Maggiorani Appleton') WHERE ano = 10 AND nome = 'C1' AND diretor_turma = 'António Maria Rivotti Maggiorani Appleton';
UPDATE turmas SET diretor_turma_id = (SELECT id FROM professores WHERE nome = 'António Maria Rivotti Maggiorani Appleton') WHERE ano = 10 AND nome = 'B1' AND diretor_turma = 'António Maria Rivotti Maggiorani Appleton';
UPDATE turmas SET diretor_turma_id = (SELECT id FROM professores WHERE nome = 'Margarida Maria Dias Nobre Bábau') WHERE ano = 12 AND nome = 'B' AND diretor_turma = 'Margarida Maria Dias Nobre Bábau';
UPDATE turmas SET diretor_turma_id = (SELECT id FROM professores WHERE nome = 'Francisco Salgado Machado De Oliveira E Maia') WHERE ano = 12 AND nome = 'A' AND diretor_turma = 'Francisco Salgado Machado De Oliveira E Maia';
UPDATE turmas SET diretor_turma_id = (SELECT id FROM professores WHERE nome = 'Susana Duarte de Santos Viola') WHERE ano = 11 AND nome = 'C' AND diretor_turma = 'Susana Duarte de Santos Viola';
UPDATE turmas SET diretor_turma_id = (SELECT id FROM professores WHERE nome = 'Inês Ribeiro Garcia De Paiva Couceiro') WHERE ano = 11 AND nome = 'B' AND diretor_turma = 'Inês Ribeiro Garcia De Paiva Couceiro';
UPDATE turmas SET diretor_turma_id = (SELECT id FROM professores WHERE nome = 'Carla Saldanha') WHERE ano = 11 AND nome = 'A' AND diretor_turma = 'Carla Alexandra dos Reis da Silva Saldanha';
UPDATE turmas SET diretor_turma_id = (SELECT id FROM professores WHERE nome = 'Carlos Manuel Costa Domingos') WHERE ano = 10 AND nome = 'C' AND diretor_turma = 'Carlos Manuel Costa Domingos';
UPDATE turmas SET diretor_turma_id = (SELECT id FROM professores WHERE nome = 'Sara Raquel Lopes De Lira') WHERE ano = 10 AND nome = 'A' AND diretor_turma = 'Sara Raquel Lopes De Lira';
UPDATE turmas SET diretor_turma_id = (SELECT id FROM professores WHERE nome = 'Concha Cal Reynolds De Sousa') WHERE ano = 10 AND nome = 'B' AND diretor_turma = 'Concha Cal Reynolds De Sousa';

COMMIT;

-- Verificação: turmas desta lista (ano+nome) cujo diretor_turma_id ficou
-- por atribuir — nome do professor não encontrado em professores.nome
-- (acentos, espaços, nome diferente do registo), ou ainda sem conta criada.
-- Corrigir à mão depois de confirmar o nome certo:
--   SELECT ano, nome, diretor_turma FROM turmas
--   WHERE diretor_turma_id IS NULL
--     AND diretor_turma IN (
--       'João Pedro Marques Sobral','Carolina Antunes Borges',
--       'Maria Da Luz Tinoco Alpoim Barbosa','João Francisco Dos Santos Neto Mariano',
--       'Ana Rita Zuzarte Reis Gomes Nunes Ribeiro','Mariana Da Silva Fontes',
--       'Fernando Tiago Rosa Franco Frazão Marques Da Silva','Diogo Nuno Martins De Brito Alves Moreira',
--       'Margarida Da Silva Marques','Jorge Manuel Rodrigues Morais Varandas Fernandes',
--       'Xavier Calvão Mestre','Sara Filipa Infante Gaspar Chambel Leitão',
--       'Mariana Pereira Alho Da Silva Ramalho Sobral','David Miguel Teixeira De Oliveira',
--       'Sofia Silva Lopes Nogueira Cabral Antunes Oliveira','David Amaro Pereira Teixeira',
--       'António Maria Rivotti Maggiorani Appleton','Margarida Maria Dias Nobre Bábau',
--       'Francisco Salgado Machado De Oliveira E Maia','Susana Duarte de Santos Viola',
--       'Inês Ribeiro Garcia De Paiva Couceiro','Carla Alexandra dos Reis da Silva Saldanha',
--       'Carlos Manuel Costa Domingos','Sara Raquel Lopes De Lira','Concha Cal Reynolds De Sousa'
--     );
--
-- Para comparar diretamente com os nomes que existem em professores:
--   SELECT id, nome, email FROM professores ORDER BY nome;
