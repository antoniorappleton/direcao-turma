-- Registo de acompanhamento do aluno (contactos com EE, notas, reuniões
-- pontuais, etc.) — timeline visível na ficha do aluno da app Direção de
-- Turma. Aditivo: não altera nada existente.
--
-- Execute este ficheiro no SQL Editor do Supabase.

BEGIN;

CREATE TABLE IF NOT EXISTS registos_aluno (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  aluno_id uuid NOT NULL REFERENCES alunos(id) ON DELETE CASCADE,
  autor_id uuid REFERENCES professores(id) ON DELETE SET NULL,
  tipo text NOT NULL DEFAULT 'nota', -- contacto_ee | reuniao | nota | outro
  data date NOT NULL DEFAULT current_date,
  resumo text NOT NULL,
  seguimento_necessario boolean DEFAULT false,
  data_seguimento date,
  seguimento_concluido boolean DEFAULT false,
  criado_em timestamp with time zone DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_registos_aluno_aluno ON registos_aluno(aluno_id);

-- Mesmo padrão de permissões já usado em Scriptorium/db/allow_delete_ocorrencias.sql
-- (CREATE OR REPLACE é seguro mesmo que estas funções já existam em produção).
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

ALTER TABLE registos_aluno ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS authenticated_all_registos_aluno ON registos_aluno;
CREATE POLICY authenticated_all_registos_aluno
  ON registos_aluno FOR ALL
  USING (public.is_current_user_professor())
  WITH CHECK (public.is_current_user_professor());

COMMIT;
