-- Fecha um espaço entre o Painel DT e o acesso real à turma.
--
-- is_current_user_professor_da_turma() (db/add_avaliacoes.sql) só
-- verificava professor_turmas — um professor que seja DT de uma turma
-- (turmas.diretor_turma_id) mas nunca a tenha adicionado à sua seleção de
-- "Turmas que leciono" não conseguia ver/editar notas dessa turma, apesar
-- de o Painel DT (que lista sempre as turmas pelo diretor_turma_id, não
-- pela seleção) lhe mostrar o link para lá. O mesmo bypass foi adicionado
-- no cliente, em app/js/core/permissions.js (canAccessTurma).
--
-- Este ficheiro só redefine a função (CREATE OR REPLACE) para também
-- aceitar o DT da turma — reaproveita is_current_user_dt_da_turma, já
-- criada em db/add_diretor_turma_id.sql. Aditivo, não cria tabelas novas,
-- seguro re-correr.
--
-- Execute no SQL Editor do Supabase depois de db/add_diretor_turma_id.sql
-- e db/add_avaliacoes.sql (que já devem ter corrido).

BEGIN;

CREATE OR REPLACE FUNCTION public.is_current_user_professor_da_turma(p_turma_id uuid)
  RETURNS boolean
  LANGUAGE sql
  STABLE
  SECURITY DEFINER
  SET search_path = public
  AS $$
    SELECT public.is_current_user_admin()
      OR public.is_current_user_dt_da_turma(p_turma_id)
      OR EXISTS (
        SELECT 1
        FROM public.professor_turmas pt
        JOIN public.professores p ON p.id = pt.professor_id
        WHERE pt.turma_id = p_turma_id
          AND lower(p.email) = lower(public.current_user_email())
      )
  $$;

COMMIT;
