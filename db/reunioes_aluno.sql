-- Reuniões com encarregados de educação, por aluno — com estado
-- pedida/agendada/realizada/cancelada (como na folha de cálculo do DT:
-- colunas "Reunião pedida" / "Reunião agendada") e os assuntos tratados.
-- Aditivo: não altera nada existente.
--
-- Execute este ficheiro no SQL Editor do Supabase.

BEGIN;

CREATE TABLE IF NOT EXISTS reunioes_aluno (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  aluno_id uuid NOT NULL REFERENCES alunos(id) ON DELETE CASCADE,
  estado text NOT NULL DEFAULT 'pedida', -- pedida | agendada | confirmada | realizada | cancelada
  data_pedida date DEFAULT current_date,
  data_agendada date,
  data_confirmada date,
  data_realizada date,
  hora time,
  local text,
  participantes text,
  assuntos text, -- assuntos a tratar (preenchido ao pedir/agendar)
  topicos text[] DEFAULT '{}'::text[], -- tópicos abordados: situacao_academica | comportamento | faltas_injustificadas | exames_clinicos | queixas | outros
  notas text, -- registo rápido preenchido durante/depois da reunião
  criado_por uuid REFERENCES professores(id) ON DELETE SET NULL,
  criado_em timestamp with time zone DEFAULT now()
);

-- ALTER explícitos: se a tabela já existia de uma corrida anterior deste
-- ficheiro (antes de "confirmada"/"topicos"/"data_confirmada" existirem),
-- o CREATE TABLE IF NOT EXISTS acima não teria adicionado estas colunas.
ALTER TABLE reunioes_aluno ADD COLUMN IF NOT EXISTS data_confirmada date;
ALTER TABLE reunioes_aluno ADD COLUMN IF NOT EXISTS topicos text[] DEFAULT '{}'::text[];

CREATE INDEX IF NOT EXISTS idx_reunioes_aluno_aluno ON reunioes_aluno(aluno_id);

-- Mesmas funções de permissão dos ficheiros anteriores (CREATE OR REPLACE é
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

ALTER TABLE reunioes_aluno ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS authenticated_all_reunioes_aluno ON reunioes_aluno;
CREATE POLICY authenticated_all_reunioes_aluno
  ON reunioes_aluno FOR ALL
  USING (public.is_current_user_professor())
  WITH CHECK (public.is_current_user_professor());

COMMIT;
