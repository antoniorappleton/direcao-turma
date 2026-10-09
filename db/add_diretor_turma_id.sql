-- Substitui a comparação por nome (turmas.diretor_turma, texto livre) por
-- uma referência real a professores — a dívida técnica já assinalada em
-- app/js/core/permissions.js e no README ("O que falta"): nomes podem
-- repetir-se ou ter pequenas diferenças (acentos, espaços), o que torna a
-- comparação por texto frágil para controlo de acesso.
--
-- `turmas.diretor_turma` (texto) não é removido — o Scriptorium continua a
-- lê-lo para mostrar/denormalizar o nome do DT em ocorrencias (ver
-- Scriptorium/db/add_diretor_turma.sql, app/js/app.js). `diretor_turma_id`
-- passa a ser a fonte de verdade para permissões; `diretor_turma` fica como
-- texto de apresentação, já sem função no controlo de acesso.
--
-- Aditivo: só adiciona coluna e substitui funções (CREATE OR REPLACE).
-- Seguro re-correr.
--
-- Execute este ficheiro no SQL Editor do Supabase, depois de
-- db/add_acesso_dt_vs_professor.sql (que já deve ter corrido).

BEGIN;

ALTER TABLE turmas
  ADD COLUMN IF NOT EXISTS diretor_turma_id uuid REFERENCES professores(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_turmas_diretor_turma_id ON turmas(diretor_turma_id);

-- Backfill a partir do nome em diretor_turma, só quando há exatamente um
-- professor com esse nome (evita atribuir o DT errado em caso de nomes
-- repetidos — esses casos ficam null e têm de ser corrigidos à mão).
WITH matches AS (
  SELECT t.id AS turma_id, array_agg(p.id) AS professor_ids
  FROM turmas t
  JOIN professores p ON p.nome = t.diretor_turma
  WHERE t.diretor_turma IS NOT NULL
  GROUP BY t.id
)
UPDATE turmas t
SET diretor_turma_id = m.professor_ids[1]
FROM matches m
WHERE t.id = m.turma_id
  AND array_length(m.professor_ids, 1) = 1
  AND t.diretor_turma_id IS NULL;

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

-- Substitui a versão de db/add_acesso_dt_vs_professor.sql (comparação por
-- nome) por uma comparação pela FK.
CREATE OR REPLACE FUNCTION public.is_current_user_dt_da_turma(p_turma_id uuid)
  RETURNS boolean
  LANGUAGE sql
  STABLE
  SECURITY DEFINER
  SET search_path = public
  AS $$
    SELECT public.is_current_user_admin()
      OR EXISTS (
        SELECT 1
        FROM public.turmas t
        JOIN public.professores p ON p.id = t.diretor_turma_id
        WHERE t.id = p_turma_id
          AND lower(p.email) = lower(public.current_user_email())
      )
  $$;

-- is_current_user_dt_do_aluno (db/add_acesso_dt_vs_professor.sql) não
-- precisa de ser redefinida: já chama is_current_user_dt_da_turma, por isso
-- passa a usar a FK automaticamente.

COMMIT;

-- Depois de confirmar os resultados abaixo, usar
-- `UPDATE turmas SET diretor_turma_id = '<professor-id>' WHERE id = '<turma-id>';`
-- para fechar os casos que o backfill não resolveu sozinho.
--
-- Turmas com diretor_turma (texto) preenchido mas diretor_turma_id ainda por
-- atribuir (nome ambíguo ou sem professor correspondente):
--   SELECT id, nome, ano, diretor_turma FROM turmas
--   WHERE diretor_turma IS NOT NULL AND diretor_turma_id IS NULL;
