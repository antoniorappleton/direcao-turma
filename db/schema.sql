-- Schema para a app "Direção de Turma" — estende o mesmo projeto Supabase
-- já usado pelo Scriptorium (partilha `professores`, `turmas`, `ciclos`,
-- `alunos`). Este script é só ADITIVO: não altera nem apaga nada do que já
-- existe, por isso é seguro correr sem afetar o Scriptorium em produção.

BEGIN;

-- Anos letivos (ex: "2026/2027")
CREATE TABLE IF NOT EXISTS anos_letivos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nome text NOT NULL UNIQUE,
  data_inicio date,
  data_fim date,
  ativo boolean DEFAULT false
);

-- Histórico de matrículas: substitui o link direto e "sem memória"
-- alunos.turma_id, permitindo saber em que turma um aluno esteve em cada
-- ano letivo, sem apagar o histórico quando muda de turma/ano.
CREATE TABLE IF NOT EXISTS matriculas (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  aluno_id uuid REFERENCES alunos(id) ON DELETE CASCADE,
  turma_id uuid REFERENCES turmas(id) ON DELETE SET NULL,
  ano_letivo_id uuid REFERENCES anos_letivos(id) ON DELETE SET NULL,
  data_inicio date DEFAULT current_date,
  data_fim date,
  estado text DEFAULT 'ativa'
);

CREATE INDEX IF NOT EXISTS idx_matriculas_aluno ON matriculas(aluno_id);
CREATE INDEX IF NOT EXISTS idx_matriculas_turma ON matriculas(turma_id);

-- Encarregados de educação
CREATE TABLE IF NOT EXISTS encarregados (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nome text NOT NULL,
  email text,
  telefone text
);

-- Relação aluno ↔ encarregado (um aluno pode ter mais que um)
CREATE TABLE IF NOT EXISTS aluno_encarregados (
  aluno_id uuid REFERENCES alunos(id) ON DELETE CASCADE,
  encarregado_id uuid REFERENCES encarregados(id) ON DELETE CASCADE,
  principal boolean DEFAULT false,
  responsavel_legal boolean DEFAULT false,
  PRIMARY KEY (aluno_id, encarregado_id)
);

-- Documentos ligados a um aluno (autorizações, atas, etc.)
CREATE TABLE IF NOT EXISTS documentos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  titulo text NOT NULL,
  categoria text,
  ficheiro_path text,
  aluno_id uuid REFERENCES alunos(id) ON DELETE CASCADE,
  ano_letivo_id uuid REFERENCES anos_letivos(id) ON DELETE SET NULL,
  criado_por uuid REFERENCES professores(id) ON DELETE SET NULL,
  criado_em timestamp with time zone DEFAULT now()
);

COMMIT;

-- Nota: RLS (Row Level Security) fica para quando as views reais estiverem
-- ligadas — ver exemplo de política em db/rls_exemplo.sql.
