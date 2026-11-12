-- "Mudar de turma" — capacidade geral para transferir um aluno de turma
-- (uma mudança normal, quando é preciso), sem perder nenhum dado do aluno:
-- mantém o mesmo id e ficha (encarregados, documentos, observações,
-- histórico); só a turma muda, e com ela o DT responsável, que passa a ser
-- automaticamente o(s) DT da turma nova (ver is_current_user_dt_da_turma,
-- já com suporte a mais do que um DT em db/add_turma_diretores.sql).
--
-- Reaproveita a tabela `matriculas` (ver db/schema.sql), que já existia
-- para isto mas ainda sem nenhuma escrita automática: fecha a matrícula
-- ativa anterior (sem apagar — fica no histórico, visível em
-- AlunosService.getHistoricoMatriculas) e abre uma nova na turma de
-- destino.
--
-- Aditivo: cria uma função nova (RPC), uma coluna nova em `matriculas`, e
-- garante que existe pelo menos um ano letivo ativo (sem o qual a
-- matrícula nova não tinha onde encaixar — `anos_letivos` nunca chegou a
-- ser populada em produção). Seguro re-correr.
--
-- Execute no SQL Editor do Supabase, depois de db/add_diretor_turma_id.sql
-- e db/add_turma_diretores.sql (ambos já devem ter corrido).

BEGIN;

ALTER TABLE matriculas ADD COLUMN IF NOT EXISTS observacoes text;

INSERT INTO anos_letivos (nome, data_inicio, data_fim, ativo)
SELECT '2026/2027', DATE '2026-09-01', DATE '2027-07-31', true
WHERE NOT EXISTS (SELECT 1 FROM anos_letivos);

CREATE OR REPLACE FUNCTION public.current_user_email()
  RETURNS text
  LANGUAGE sql
  STABLE
  AS $$
    SELECT COALESCE(
      auth.jwt() ->> 'email',
      current_setting('request.jwt.claims', true)::json ->> 'email'
    )
  $$;

-- Pode mudar a turma de um aluno quem for admin, ou DT (atual ou novo — de
-- qualquer um dos dois, não precisa de ser DT das duas) de pelo menos uma
-- das turmas envolvidas. Um professor só de disciplina, sem ser DT de
-- nenhuma das duas, não pode transferir o aluno.
CREATE OR REPLACE FUNCTION public.mudar_turma_aluno(
  p_aluno_id uuid,
  p_nova_turma_id uuid,
  p_motivo text DEFAULT NULL
)
  RETURNS void
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path = public
  AS $$
  DECLARE
    v_turma_antiga uuid;
    v_ano_letivo_id uuid;
  BEGIN
    SELECT turma_id INTO v_turma_antiga FROM public.alunos WHERE id = p_aluno_id;

    IF NOT (
      public.is_current_user_admin()
      OR (v_turma_antiga IS NOT NULL AND public.is_current_user_dt_da_turma(v_turma_antiga))
      OR public.is_current_user_dt_da_turma(p_nova_turma_id)
    ) THEN
      RAISE EXCEPTION 'Sem permissão para mudar este aluno de turma.';
    END IF;

    SELECT id INTO v_ano_letivo_id FROM public.anos_letivos WHERE ativo = true LIMIT 1;

    UPDATE public.matriculas
    SET data_fim = current_date, estado = 'transferida'
    WHERE aluno_id = p_aluno_id AND estado = 'ativa' AND data_fim IS NULL;

    INSERT INTO public.matriculas (aluno_id, turma_id, ano_letivo_id, data_inicio, estado, observacoes)
    VALUES (p_aluno_id, p_nova_turma_id, v_ano_letivo_id, current_date, 'ativa', p_motivo);

    UPDATE public.alunos SET turma_id = p_nova_turma_id WHERE id = p_aluno_id;
  END;
  $$;

GRANT EXECUTE ON FUNCTION public.mudar_turma_aluno(uuid, uuid, text) TO authenticated;

COMMIT;
