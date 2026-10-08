-- Avaliações dos alunos por disciplina/período (separador "Avaliações" em
-- "A minha turma"). Aditivo: não altera nada existente.
--
-- `turma_id` é denormalizado (tal como ocorrencias.turma/ano já fazem):
-- guarda a turma do aluno no momento do registo, e é o que a política de
-- RLS usa para decidir acesso — independente de mudanças futuras de turma.
--
-- Disciplina é texto livre (sem tabela de catálogo) — ver
-- AvaliacoesService.getDisciplinasDaTurma, que sugere os valores já usados
-- nessa turma via datalist no formulário.
--
-- Execute este ficheiro no SQL Editor do Supabase.

BEGIN;

CREATE TABLE IF NOT EXISTS avaliacoes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  aluno_id uuid NOT NULL REFERENCES alunos(id) ON DELETE CASCADE,
  turma_id uuid NOT NULL REFERENCES turmas(id) ON DELETE CASCADE,
  disciplina text NOT NULL,
  periodo smallint NOT NULL CHECK (periodo IN (1, 2, 3)),
  tipo text NOT NULL DEFAULT 'teste', -- teste | questao_aula | trabalho | apresentacao | oralidade | projeto | ficha | intercalar | outro (intercalar só em periodo 1/2, validado na app)
  titulo text NOT NULL,
  data date NOT NULL DEFAULT current_date,
  nota numeric(5, 2),
  escala text NOT NULL DEFAULT '0-20',
  peso numeric(5, 2),
  observacao text,
  criado_por uuid REFERENCES professores(id) ON DELETE SET NULL,
  criado_em timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_avaliacoes_turma ON avaliacoes(turma_id);
CREATE INDEX IF NOT EXISTS idx_avaliacoes_aluno ON avaliacoes(aluno_id);
CREATE INDEX IF NOT EXISTS idx_avaliacoes_turma_periodo ON avaliacoes(turma_id, periodo);
CREATE INDEX IF NOT EXISTS idx_avaliacoes_turma_disciplina ON avaliacoes(turma_id, disciplina);

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

-- Ao contrário das restantes tabelas deste projeto (que só verificam "é
-- professor", sem olhar à turma — ver db/registos_aluno.sql,
-- db/reunioes_aluno.sql, db/documentos_turma_storage.sql), esta tabela fica
-- protegida por turma desde o início: só quem leciona a turma (presente em
-- professor_turmas, ver db/add_professor_turmas.sql) ou é admin pode
-- ler/escrever as suas avaliações.
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

ALTER TABLE avaliacoes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS professor_turma_select_avaliacoes ON avaliacoes;
CREATE POLICY professor_turma_select_avaliacoes
  ON avaliacoes FOR SELECT
  TO authenticated
  USING (public.is_current_user_professor_da_turma(turma_id));

DROP POLICY IF EXISTS professor_turma_insert_avaliacoes ON avaliacoes;
CREATE POLICY professor_turma_insert_avaliacoes
  ON avaliacoes FOR INSERT
  TO authenticated
  WITH CHECK (public.is_current_user_professor_da_turma(turma_id));

DROP POLICY IF EXISTS professor_turma_update_avaliacoes ON avaliacoes;
CREATE POLICY professor_turma_update_avaliacoes
  ON avaliacoes FOR UPDATE
  TO authenticated
  USING (public.is_current_user_professor_da_turma(turma_id))
  WITH CHECK (public.is_current_user_professor_da_turma(turma_id));

DROP POLICY IF EXISTS professor_turma_delete_avaliacoes ON avaliacoes;
CREATE POLICY professor_turma_delete_avaliacoes
  ON avaliacoes FOR DELETE
  TO authenticated
  USING (public.is_current_user_professor_da_turma(turma_id));

COMMIT;
