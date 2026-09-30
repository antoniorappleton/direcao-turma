-- Permite a qualquer professor autenticado corrigir/preencher o número
-- interno de um aluno a partir da app Direção de Turma.
--
-- `alunos` é uma tabela partilhada com o Scriptorium e a sua RLS de produção
-- (Scriptorium/db/admin_manage_alunos_turmas.sql) só permite escrita a
-- admins. Em vez de abrir UPDATE geral sobre `alunos` a qualquer professor
-- (o que arriscaria nome/turma/etc. serem alterados por engano), criamos uma
-- função SECURITY DEFINER que só altera a coluna `numero_interno` — mesmo
-- padrão já usado em Scriptorium/db/allow_delete_ocorrencias.sql para
-- `delete_ocorrencia_by_id`.
--
-- Execute este ficheiro no SQL Editor do Supabase.

BEGIN;

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

CREATE OR REPLACE FUNCTION public.is_current_user_professor()
  RETURNS boolean
  LANGUAGE sql
  STABLE
  SECURITY DEFINER
  SET search_path = public
  AS $$
    SELECT EXISTS (
      SELECT 1
      FROM public.professores p
      WHERE lower(p.email) = lower(public.current_user_email())
    )
  $$;

CREATE OR REPLACE FUNCTION public.atualizar_numero_interno_aluno(p_aluno_id uuid, p_numero_interno text)
  RETURNS void
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path = public
  AS $$
  BEGIN
    IF NOT public.is_current_user_professor() THEN
      RAISE EXCEPTION 'Sem permissão para atualizar aluno.';
    END IF;

    UPDATE public.alunos
    SET numero_interno = p_numero_interno
    WHERE id = p_aluno_id;
  END;
  $$;

GRANT EXECUTE ON FUNCTION public.atualizar_numero_interno_aluno(uuid, text) TO authenticated;

COMMIT;
