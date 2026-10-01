-- Turmas que cada professor leciona ("as minhas turmas"), escolhidas pelo
-- próprio num checklist ao entrar pela primeira vez — definem o acesso no
-- painel DT (ver js/core/permissions.js: canAccessTurma). Independente de
-- ser ou não o diretor de turma (turmas.diretor_turma é texto livre,
-- usado só para pré-selecionar o checklist): um professor pode lecionar
-- turmas de que não é DT.

BEGIN;

CREATE TABLE IF NOT EXISTS professor_turmas (
  professor_id uuid NOT NULL REFERENCES professores(id) ON DELETE CASCADE,
  turma_id uuid NOT NULL REFERENCES turmas(id) ON DELETE CASCADE,
  criado_em timestamp with time zone DEFAULT now(),
  PRIMARY KEY (professor_id, turma_id)
);

CREATE INDEX IF NOT EXISTS idx_professor_turmas_professor ON professor_turmas(professor_id);

-- Mesmo padrão de permissões já usado em db/registos_aluno.sql (CREATE OR
-- REPLACE é seguro mesmo que estas funções já existam em produção).
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

ALTER TABLE professor_turmas ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS authenticated_all_professor_turmas ON professor_turmas;
CREATE POLICY authenticated_all_professor_turmas
  ON professor_turmas FOR ALL
  USING (public.is_current_user_professor())
  WITH CHECK (public.is_current_user_professor());

COMMIT;
