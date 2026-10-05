-- Estende a tabela `documentos` (ver db/schema.sql e
-- db/documentos_turma_storage.sql) para também guardar documentos do
-- próprio professor (ex: horário), não só de aluno/turma. Aditivo: não
-- altera nem apaga nada existente.
--
-- Execute este ficheiro no SQL Editor do Supabase, depois dos dois scripts
-- acima.

BEGIN;

ALTER TABLE documentos ADD COLUMN IF NOT EXISTS professor_id uuid REFERENCES professores(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_documentos_professor ON documentos(professor_id);

-- Substitui o check anterior (aluno_id OR turma_id) por um que também aceita
-- professor_id, mantendo a regra de que um documento pertence a pelo menos
-- um "dono".
ALTER TABLE documentos DROP CONSTRAINT IF EXISTS documentos_aluno_ou_turma_check;
ALTER TABLE documentos ADD CONSTRAINT documentos_aluno_ou_turma_check
  CHECK (aluno_id IS NOT NULL OR turma_id IS NOT NULL OR professor_id IS NOT NULL);

-- RLS e política de Storage já cobrem esta coluna: authenticated_all_documentos
-- (db/documentos_turma_storage.sql) é FOR ALL para qualquer professor
-- autenticado, tal como o bucket "documentos-dt" — não é preciso nenhuma
-- política nova. A app filtra por professor_id em perfil.html.

COMMIT;
