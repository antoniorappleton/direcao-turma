-- `encarregados` e `aluno_encarregados` têm RLS ativo sem nenhuma política
-- (por isso o INSERT do popup "Adicionar Encarregado" falha com 42501 / "new
-- row violates row-level security policy"). Este script permite a
-- professores autenticados (presentes em public.professores) gerir estas
-- duas tabelas.
--
-- Reutiliza public.is_current_user_professor(), já criada no mesmo projeto
-- Supabase pelo Scriptorium (ver Scriptorium/db/allow_delete_ocorrencias.sql
-- — direcao-turma partilha professores/turmas/ciclos/alunos com o
-- Scriptorium, confirmar db/schema.sql). Se a função não existir ainda,
-- correr primeiro esse ficheiro.
--
-- Execute este ficheiro no SQL Editor do Supabase.

BEGIN;

ALTER TABLE IF EXISTS encarregados ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS aluno_encarregados ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS professores_manage_encarregados ON encarregados;
CREATE POLICY professores_manage_encarregados
  ON encarregados FOR ALL
  TO authenticated
  USING (public.is_current_user_professor())
  WITH CHECK (public.is_current_user_professor());

DROP POLICY IF EXISTS professores_manage_aluno_encarregados ON aluno_encarregados;
CREATE POLICY professores_manage_aluno_encarregados
  ON aluno_encarregados FOR ALL
  TO authenticated
  USING (public.is_current_user_professor())
  WITH CHECK (public.is_current_user_professor());

COMMIT;
