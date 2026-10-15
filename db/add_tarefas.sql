-- Tarefas pessoais do professor — lista simples de organização em "O meu
-- perfil" (ver app/perfil.html, app/js/services/tarefas.service.js).
-- Aditivo: não altera nada existente.
--
-- Execute este ficheiro no SQL Editor do Supabase.

BEGIN;

CREATE TABLE IF NOT EXISTS tarefas (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  professor_id uuid NOT NULL REFERENCES professores(id) ON DELETE CASCADE,
  titulo text NOT NULL,
  concluida boolean NOT NULL DEFAULT false,
  criado_em timestamptz DEFAULT now(),
  concluida_em timestamptz
);

CREATE INDEX IF NOT EXISTS idx_tarefas_professor ON tarefas(professor_id);

-- Mesmas funções de permissão já usadas nos restantes ficheiros deste
-- projeto (CREATE OR REPLACE é seguro mesmo que já existam).
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

CREATE OR REPLACE FUNCTION public.is_current_user_admin()
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
        AND p.role = 'admin'
    )
  $$;

-- Tarefas são pessoais (não partilhadas com a turma): cada professor só vê
-- e edita as suas próprias; admin vê tudo só para efeitos de suporte.
CREATE OR REPLACE FUNCTION public.is_current_user_owner_of_professor(p_professor_id uuid)
  RETURNS boolean
  LANGUAGE sql
  STABLE
  SECURITY DEFINER
  SET search_path = public
  AS $$
    SELECT public.is_current_user_admin()
      OR EXISTS (
        SELECT 1
        FROM public.professores p
        WHERE p.id = p_professor_id
          AND lower(p.email) = lower(public.current_user_email())
      )
  $$;

ALTER TABLE tarefas ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS professor_select_tarefas ON tarefas;
CREATE POLICY professor_select_tarefas
  ON tarefas FOR SELECT
  TO authenticated
  USING (public.is_current_user_owner_of_professor(professor_id));

DROP POLICY IF EXISTS professor_insert_tarefas ON tarefas;
CREATE POLICY professor_insert_tarefas
  ON tarefas FOR INSERT
  TO authenticated
  WITH CHECK (public.is_current_user_owner_of_professor(professor_id));

DROP POLICY IF EXISTS professor_update_tarefas ON tarefas;
CREATE POLICY professor_update_tarefas
  ON tarefas FOR UPDATE
  TO authenticated
  USING (public.is_current_user_owner_of_professor(professor_id))
  WITH CHECK (public.is_current_user_owner_of_professor(professor_id));

DROP POLICY IF EXISTS professor_delete_tarefas ON tarefas;
CREATE POLICY professor_delete_tarefas
  ON tarefas FOR DELETE
  TO authenticated
  USING (public.is_current_user_owner_of_professor(professor_id));

COMMIT;
