-- Estende a tabela `documentos` (já criada em db/schema.sql, mas ainda sem
-- nenhum código a usá-la) para também suportar documentos de turma (não só
-- de aluno), e cria o bucket de Storage privado onde os ficheiros ficam.
-- Aditivo: não altera nada existente.
--
-- Execute este ficheiro no SQL Editor do Supabase.

BEGIN;

ALTER TABLE documentos ADD COLUMN IF NOT EXISTS turma_id uuid REFERENCES turmas(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_documentos_aluno ON documentos(aluno_id);
CREATE INDEX IF NOT EXISTS idx_documentos_turma ON documentos(turma_id);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'documentos_aluno_ou_turma_check'
  ) THEN
    ALTER TABLE documentos ADD CONSTRAINT documentos_aluno_ou_turma_check
      CHECK (aluno_id IS NOT NULL OR turma_id IS NOT NULL);
  END IF;
END $$;

-- Mesmas funções de permissão de db/registos_aluno.sql (CREATE OR REPLACE é
-- seguro mesmo que já existam).
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

ALTER TABLE documentos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS authenticated_all_documentos ON documentos;
CREATE POLICY authenticated_all_documentos
  ON documentos FOR ALL
  USING (public.is_current_user_professor())
  WITH CHECK (public.is_current_user_professor());

-- Bucket privado (não público) — os ficheiros só são acedidos via signed URL
-- gerada pela app, nunca por URL direta.
INSERT INTO storage.buckets (id, name, public)
VALUES ('documentos-dt', 'documentos-dt', false)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS authenticated_all_documentos_dt_storage ON storage.objects;
CREATE POLICY authenticated_all_documentos_dt_storage
  ON storage.objects FOR ALL
  USING (bucket_id = 'documentos-dt' AND public.is_current_user_professor())
  WITH CHECK (bucket_id = 'documentos-dt' AND public.is_current_user_professor());

COMMIT;

-- Nota: se o INSERT em storage.buckets falhar por restrição do plano
-- Supabase, cria o bucket manualmente em Studio → Storage → New bucket,
-- com o nome "documentos-dt" e "Public bucket" DESMARCADO — depois corre o
-- resto deste ficheiro normalmente (o INSERT com ON CONFLICT torna-se no-op).
