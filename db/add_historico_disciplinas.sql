-- Histórico académico de anos letivos anteriores, por aluno/disciplina —
-- para não se perder nada na transição de ano (um aluno muda de turma todos
-- os anos, mas o histórico de notas deve continuar acessível ao DT atual).
--
-- Ao contrário de `avaliacoes` (db/add_avaliacoes.sql), aqui não há
-- `turma_id` a apontar para `turmas` — a turma de um ano anterior já não
-- existe como linha ativa relevante (ex: "9.º C" de 2025/2026). Por isso o
-- acesso é decidido pela turma ATUAL do aluno (alunos.turma_id), não pela
-- turma do histórico — assim o DT de hoje (10.º A1/B1/C1) continua a ver o
-- histórico de 9.º ano dos seus alunos, mesmo sem ter sido DT deles nessa
-- altura.
--
-- Aditivo: não altera nada existente. Seguro re-correr (idempotente via
-- ON CONFLICT).
--
-- Execute este ficheiro no SQL Editor do Supabase (depois de
-- db/add_avaliacoes.sql, de que reutiliza is_current_user_professor_da_turma).
--
-- Este ficheiro tem só o schema/RLS (genérico, sem dados pessoais) — é por
-- isso que vai para o repositório git, que é público. Os INSERTs com nomes
-- e notas reais de alunos ficam em db/local/importar_9ano_2025_2026.sql,
-- fora do git (ver .gitignore), para nunca serem publicados. Corre este
-- ficheiro primeiro, depois esse.

BEGIN;

CREATE TABLE IF NOT EXISTS historico_disciplinas (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  aluno_id uuid NOT NULL REFERENCES alunos(id) ON DELETE CASCADE,
  ano_letivo text NOT NULL, -- "2025/2026"
  ano int,                   -- 9 (ano de escolaridade nesse ano letivo)
  turma_nome text,           -- "9.º C" — histórico, sem FK para turmas
  disciplina text NOT NULL,
  nota numeric(5, 2),
  escala text NOT NULL DEFAULT '0-20',
  media_geral numeric(5, 2), -- média do período/ano (repetida por disciplina — resumo do aluno nesse ano)
  averbamento text,          -- ex: "Admitido a Exame"
  observacoes text,
  fonte text,                -- ficheiro/pauta de origem, para rastreabilidade
  criado_por uuid REFERENCES professores(id) ON DELETE SET NULL,
  criado_em timestamptz DEFAULT now(),
  UNIQUE (aluno_id, ano_letivo, disciplina)
);

CREATE INDEX IF NOT EXISTS idx_historico_disciplinas_aluno ON historico_disciplinas(aluno_id);
CREATE INDEX IF NOT EXISTS idx_historico_disciplinas_aluno_ano ON historico_disciplinas(aluno_id, ano_letivo);

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

-- Resolve o acesso pela turma ATUAL do aluno (não por nenhuma turma
-- guardada no histórico) — ver nota no topo do ficheiro.
CREATE OR REPLACE FUNCTION public.is_current_user_professor_do_aluno(p_aluno_id uuid)
  RETURNS boolean
  LANGUAGE sql
  STABLE
  SECURITY DEFINER
  SET search_path = public
  AS $$
    SELECT public.is_current_user_professor_da_turma(
      (SELECT turma_id FROM public.alunos WHERE id = p_aluno_id)
    )
  $$;

ALTER TABLE historico_disciplinas ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS professor_aluno_select_historico ON historico_disciplinas;
CREATE POLICY professor_aluno_select_historico
  ON historico_disciplinas FOR SELECT
  TO authenticated
  USING (public.is_current_user_professor_do_aluno(aluno_id));

DROP POLICY IF EXISTS professor_aluno_insert_historico ON historico_disciplinas;
CREATE POLICY professor_aluno_insert_historico
  ON historico_disciplinas FOR INSERT
  TO authenticated
  WITH CHECK (public.is_current_user_professor_do_aluno(aluno_id));

DROP POLICY IF EXISTS professor_aluno_update_historico ON historico_disciplinas;
CREATE POLICY professor_aluno_update_historico
  ON historico_disciplinas FOR UPDATE
  TO authenticated
  USING (public.is_current_user_professor_do_aluno(aluno_id))
  WITH CHECK (public.is_current_user_professor_do_aluno(aluno_id));

DROP POLICY IF EXISTS professor_aluno_delete_historico ON historico_disciplinas;
CREATE POLICY professor_aluno_delete_historico
  ON historico_disciplinas FOR DELETE
  TO authenticated
  USING (public.is_current_user_professor_do_aluno(aluno_id));

COMMIT;

-- A importação de dados reais (nomes/notas de alunos) está em
-- db/local/importar_9ano_2025_2026.sql — fora do git, corre-a a seguir a
-- esta.
