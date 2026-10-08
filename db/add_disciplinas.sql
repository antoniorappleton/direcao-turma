-- Catálogo de disciplinas + plano curricular por turma (ver separador
-- "Avaliações" em "A minha turma"). Substitui, para quem já tem o hábito de
-- escrever a disciplina de cabeça, a sugestão "aprendida" a partir de
-- avaliações já registadas (db/add_avaliacoes.sql) por uma lista oficial,
-- pré-carregada a partir do horário da turma. `avaliacoes.disciplina`
-- continua a ser texto livre — este catálogo só alimenta as sugestões no
-- formulário (ver AvaliacoesService.getDisciplinasDaTurma), não há FK.
--
-- Aditivo: não altera nada existente.
--
-- Execute este ficheiro no SQL Editor do Supabase (depois de
-- db/add_professor_turmas.sql, que já deve ter corrido).

BEGIN;

CREATE TABLE IF NOT EXISTS disciplinas (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nome text NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS turma_disciplinas (
  turma_id uuid NOT NULL REFERENCES turmas(id) ON DELETE CASCADE,
  disciplina_id uuid NOT NULL REFERENCES disciplinas(id) ON DELETE CASCADE,
  PRIMARY KEY (turma_id, disciplina_id)
);

CREATE INDEX IF NOT EXISTS idx_turma_disciplinas_turma ON turma_disciplinas(turma_id);

-- Mesmas funções de permissão já usadas em db/add_avaliacoes.sql
-- (CREATE OR REPLACE é seguro mesmo que já existam — redefinidas aqui para
-- este ficheiro não depender da ordem em que os scripts são corridos).
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

CREATE OR REPLACE FUNCTION public.is_current_user_professor_da_turma(p_turma_id uuid)
  RETURNS boolean
  LANGUAGE sql
  STABLE
  SECURITY DEFINER
  SET search_path = public
  AS $$
    SELECT public.is_current_user_admin()
      OR EXISTS (
        SELECT 1
        FROM public.professor_turmas pt
        JOIN public.professores p ON p.id = pt.professor_id
        WHERE pt.turma_id = p_turma_id
          AND lower(p.email) = lower(public.current_user_email())
      )
  $$;

ALTER TABLE disciplinas ENABLE ROW LEVEL SECURITY;
ALTER TABLE turma_disciplinas ENABLE ROW LEVEL SECURITY;

-- disciplinas: catálogo global — qualquer professor autenticado lê; só
-- admin gere (mesmo padrão de db/admin_manage_alunos_turmas.sql do
-- Scriptorium para turmas/ciclos).
DROP POLICY IF EXISTS authenticated_select_disciplinas ON disciplinas;
CREATE POLICY authenticated_select_disciplinas
  ON disciplinas FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS admins_manage_disciplinas ON disciplinas;
CREATE POLICY admins_manage_disciplinas
  ON disciplinas FOR ALL
  TO authenticated
  USING (public.is_current_user_admin())
  WITH CHECK (public.is_current_user_admin());

-- turma_disciplinas: só quem leciona a turma (ou admin) vê o plano
-- curricular dela; só admin o gere.
DROP POLICY IF EXISTS professor_turma_select_turma_disciplinas ON turma_disciplinas;
CREATE POLICY professor_turma_select_turma_disciplinas
  ON turma_disciplinas FOR SELECT
  TO authenticated
  USING (public.is_current_user_professor_da_turma(turma_id));

DROP POLICY IF EXISTS admins_manage_turma_disciplinas ON turma_disciplinas;
CREATE POLICY admins_manage_turma_disciplinas
  ON turma_disciplinas FOR ALL
  TO authenticated
  USING (public.is_current_user_admin())
  WITH CHECK (public.is_current_user_admin());

-- Catálogo global de disciplinas — extraído do horário da turma 10.º A1
-- (APECEF/Colégio de S. José, ano letivo 2026/2027). Siglas mantidas como
-- aparecem no horário (ET, FQ, INT-FIL) para não arriscar expandir mal o
-- nome oficial.
INSERT INTO disciplinas (nome) VALUES
  ('ET'),
  ('Educação Física'),
  ('Matemática'),
  ('Programação'),
  ('INT-FIL'),
  ('Inglês'),
  ('Português'),
  ('FQ'),
  ('Religião'),
  ('Assembleia'),
  ('Teatro'),
  ('Ilustração')
ON CONFLICT (nome) DO NOTHING;

-- Plano curricular da 10.º A1 — liga a turma (já criada em
-- Scriptorium/db/import_alunos_2026_2027.sql: nome='A1', ano=10) a todas as
-- disciplinas acima.
INSERT INTO turma_disciplinas (turma_id, disciplina_id)
SELECT t.id, d.id
FROM turmas t
CROSS JOIN disciplinas d
WHERE t.nome = 'A1'
  AND t.ano = 10
  AND d.nome IN ('ET', 'Educação Física', 'Matemática', 'Programação', 'INT-FIL', 'Inglês', 'Português', 'FQ', 'Religião', 'Assembleia', 'Teatro', 'Ilustração')
ON CONFLICT (turma_id, disciplina_id) DO NOTHING;

COMMIT;
