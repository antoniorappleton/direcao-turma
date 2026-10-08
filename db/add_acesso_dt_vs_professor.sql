-- Acesso diferenciado: Diretor de Turma (DT) vs. professor de uma
-- disciplina que não é DT dessa turma.
--
-- Até agora, qualquer professor atribuído a uma turma (presente em
-- professor_turmas, ver db/add_professor_turmas.sql) tinha acesso igual a
-- tudo sobre os alunos dessa turma — encarregados, acompanhamento,
-- reuniões, documentos, histórico — porque as políticas destas tabelas só
-- verificavam "é professor" (is_current_user_professor()), sem distinguir
-- DT de professor de disciplina.
--
-- `avaliacoes` fica tal como está (db/add_avaliacoes.sql): continua aberta
-- a "qualquer professor da turma" — é exatamente isso que um professor de
-- disciplina (não-DT) precisa para dar notas.
--
-- Este ficheiro aperta as restantes tabelas para "só o DT desta turma (ou
-- admin)", usando o mesmo mecanismo já usado em minhas-turmas.html para
-- mostrar o badge "· DT" — turmas.diretor_turma (nome em texto livre)
-- comparado com professores.nome — e que já estava desenhado, mas nunca
-- ativado, em db/rls_exemplo.sql.
--
-- Aditivo: não cria tabelas novas, só substitui políticas existentes.
-- Seguro re-correr.
--
-- Execute este ficheiro no SQL Editor do Supabase (depois de
-- db/add_professor_turmas.sql, db/registos_aluno.sql,
-- db/reunioes_aluno.sql, db/allow_manage_encarregados.sql,
-- db/documentos_turma_storage.sql e db/add_historico_disciplinas.sql, que
-- já devem ter corrido).

BEGIN;

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

-- DT desta turma = o nome em turmas.diretor_turma bate com o professor
-- autenticado (mesma comparação que permissions.js isDiretorDaTurma faz no
-- cliente, só que aqui aplicada a sério, não só cosmeticamente).
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
        JOIN public.professores p ON p.nome = t.diretor_turma
        WHERE t.id = p_turma_id
          AND lower(p.email) = lower(public.current_user_email())
      )
  $$;

CREATE OR REPLACE FUNCTION public.is_current_user_dt_do_aluno(p_aluno_id uuid)
  RETURNS boolean
  LANGUAGE sql
  STABLE
  SECURITY DEFINER
  SET search_path = public
  AS $$
    SELECT public.is_current_user_dt_da_turma(
      (SELECT turma_id FROM public.alunos WHERE id = p_aluno_id)
    )
  $$;

-- ---------------------------------------------------------------------
-- registos_aluno (Acompanhamento) — era is_current_user_professor() em
-- db/registos_aluno.sql (qualquer professor, de qualquer turma).
-- ---------------------------------------------------------------------
ALTER TABLE registos_aluno ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS authenticated_all_registos_aluno ON registos_aluno;
CREATE POLICY dt_manage_registos_aluno
  ON registos_aluno FOR ALL
  TO authenticated
  USING (public.is_current_user_dt_do_aluno(aluno_id))
  WITH CHECK (public.is_current_user_dt_do_aluno(aluno_id));

-- ---------------------------------------------------------------------
-- reunioes_aluno — era is_current_user_professor() em
-- db/reunioes_aluno.sql.
-- ---------------------------------------------------------------------
ALTER TABLE reunioes_aluno ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS authenticated_all_reunioes_aluno ON reunioes_aluno;
CREATE POLICY dt_manage_reunioes_aluno
  ON reunioes_aluno FOR ALL
  TO authenticated
  USING (public.is_current_user_dt_do_aluno(aluno_id))
  WITH CHECK (public.is_current_user_dt_do_aluno(aluno_id));

-- ---------------------------------------------------------------------
-- aluno_encarregados (ligação aluno↔encarregado) — era
-- is_current_user_professor() em db/allow_manage_encarregados.sql.
-- ---------------------------------------------------------------------
ALTER TABLE aluno_encarregados ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS professores_manage_aluno_encarregados ON aluno_encarregados;
CREATE POLICY dt_manage_aluno_encarregados
  ON aluno_encarregados FOR ALL
  TO authenticated
  USING (public.is_current_user_dt_do_aluno(aluno_id))
  WITH CHECK (public.is_current_user_dt_do_aluno(aluno_id));

-- ---------------------------------------------------------------------
-- encarregados — era is_current_user_professor() em
-- db/allow_manage_encarregados.sql. Leitura/edição/remoção só para o DT de
-- algum aluno ligado a este encarregado; criação fica aberta a qualquer
-- professor (um registo "solto", ainda sem ligação em aluno_encarregados,
-- não aparece em lado nenhum da app — o controlo real está na ligação,
-- já apertada acima).
-- ---------------------------------------------------------------------
ALTER TABLE encarregados ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS professores_manage_encarregados ON encarregados;

DROP POLICY IF EXISTS authenticated_insert_encarregados ON encarregados;
CREATE POLICY authenticated_insert_encarregados
  ON encarregados FOR INSERT
  TO authenticated
  WITH CHECK (true);

DROP POLICY IF EXISTS dt_select_encarregados ON encarregados;
CREATE POLICY dt_select_encarregados
  ON encarregados FOR SELECT
  TO authenticated
  USING (
    public.is_current_user_admin()
    OR EXISTS (
      SELECT 1 FROM public.aluno_encarregados ae
      WHERE ae.encarregado_id = encarregados.id
        AND public.is_current_user_dt_do_aluno(ae.aluno_id)
    )
  );

DROP POLICY IF EXISTS dt_update_encarregados ON encarregados;
CREATE POLICY dt_update_encarregados
  ON encarregados FOR UPDATE
  TO authenticated
  USING (
    public.is_current_user_admin()
    OR EXISTS (
      SELECT 1 FROM public.aluno_encarregados ae
      WHERE ae.encarregado_id = encarregados.id
        AND public.is_current_user_dt_do_aluno(ae.aluno_id)
    )
  )
  WITH CHECK (
    public.is_current_user_admin()
    OR EXISTS (
      SELECT 1 FROM public.aluno_encarregados ae
      WHERE ae.encarregado_id = encarregados.id
        AND public.is_current_user_dt_do_aluno(ae.aluno_id)
    )
  );

DROP POLICY IF EXISTS dt_delete_encarregados ON encarregados;
CREATE POLICY dt_delete_encarregados
  ON encarregados FOR DELETE
  TO authenticated
  USING (
    public.is_current_user_admin()
    OR EXISTS (
      SELECT 1 FROM public.aluno_encarregados ae
      WHERE ae.encarregado_id = encarregados.id
        AND public.is_current_user_dt_do_aluno(ae.aluno_id)
    )
  );

-- ---------------------------------------------------------------------
-- documentos (de aluno OU de turma) — era is_current_user_professor() em
-- db/documentos_turma_storage.sql.
-- ---------------------------------------------------------------------
ALTER TABLE documentos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS authenticated_all_documentos ON documentos;
CREATE POLICY dt_manage_documentos
  ON documentos FOR ALL
  TO authenticated
  USING (
    public.is_current_user_admin()
    OR (aluno_id IS NOT NULL AND public.is_current_user_dt_do_aluno(aluno_id))
    OR (turma_id IS NOT NULL AND public.is_current_user_dt_da_turma(turma_id))
  )
  WITH CHECK (
    public.is_current_user_admin()
    OR (aluno_id IS NOT NULL AND public.is_current_user_dt_do_aluno(aluno_id))
    OR (turma_id IS NOT NULL AND public.is_current_user_dt_da_turma(turma_id))
  );

-- Nota: a política de storage.objects do bucket 'documentos-dt' (ver
-- db/documentos_turma_storage.sql) continua a verificar só "é professor" —
-- não dá para resolver aluno_id/turma_id a partir do path sem parsing
-- extra. Na prática não é explorável: um professor não-DT nunca chega a
-- obter um ficheiro_path real, porque a tabela documentos acima já está
-- fechada. Fica como possível reforço para mais tarde.

-- ---------------------------------------------------------------------
-- historico_disciplinas — era is_current_user_professor_do_aluno(aluno_id)
-- em db/add_historico_disciplinas.sql (qualquer professor da turma atual
-- do aluno). Passa a ser só o DT.
-- ---------------------------------------------------------------------
ALTER TABLE historico_disciplinas ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS professor_aluno_select_historico ON historico_disciplinas;
DROP POLICY IF EXISTS professor_aluno_insert_historico ON historico_disciplinas;
DROP POLICY IF EXISTS professor_aluno_update_historico ON historico_disciplinas;
DROP POLICY IF EXISTS professor_aluno_delete_historico ON historico_disciplinas;

CREATE POLICY dt_manage_historico_disciplinas
  ON historico_disciplinas FOR ALL
  TO authenticated
  USING (public.is_current_user_dt_do_aluno(aluno_id))
  WITH CHECK (public.is_current_user_dt_do_aluno(aluno_id));

COMMIT;
