-- Permite mais do que um Diretor de Turma (DT) na mesma turma, em
-- simultâneo. `turmas.diretor_turma_id` (ver db/add_diretor_turma_id.sql)
-- continua a ser o DT "principal" — o único usado para apresentação e
-- denormalização com o Scriptorium, via `turmas.diretor_turma` (texto).
-- Esta tabela nova guarda DT adicionais, com exatamente os mesmos direitos
-- de acesso que o DT principal (ver is_current_user_dt_da_turma, abaixo).
--
-- Aditivo: só acrescenta uma tabela nova e substitui
-- is_current_user_dt_da_turma (CREATE OR REPLACE) para também contar os DT
-- adicionais. Não altera nem apaga nada do que já existe. Seguro re-correr.
--
-- Execute no SQL Editor do Supabase, depois de db/add_diretor_turma_id.sql
-- (que já deve ter corrido — cria is_current_user_admin e a versão base de
-- is_current_user_dt_da_turma que esta substitui) e de
-- db/allow_manage_encarregados.sql (cria is_current_user_professor, usada
-- na política de leitura abaixo).

BEGIN;

CREATE TABLE IF NOT EXISTS turma_diretores (
  turma_id uuid NOT NULL REFERENCES turmas(id) ON DELETE CASCADE,
  professor_id uuid NOT NULL REFERENCES professores(id) ON DELETE CASCADE,
  criado_em timestamp with time zone DEFAULT now(),
  PRIMARY KEY (turma_id, professor_id)
);

CREATE INDEX IF NOT EXISTS idx_turma_diretores_professor ON turma_diretores(professor_id);

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

-- Substitui a versão de db/add_diretor_turma_id.sql: mesma regra (admin, ou
-- é o diretor_turma_id desta turma), mais "ou está em turma_diretores para
-- esta turma". is_current_user_dt_do_aluno (db/add_acesso_dt_vs_professor.sql)
-- não precisa de ser redefinida: já chama esta função.
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
      OR EXISTS (
        SELECT 1
        FROM public.turma_diretores td
        JOIN public.professores p ON p.id = td.professor_id
        WHERE td.turma_id = p_turma_id
          AND lower(p.email) = lower(public.current_user_email())
      )
  $$;

-- Leitura aberta a qualquer professor autenticado (a app precisa de saber
-- quem são os DT adicionais de uma turma para os mostrar/calcular acessos,
-- tal como já lê diretor_turma_id); escrita só por admin — atribuir DT
-- continua a ser uma decisão administrativa, sem self-service na app, tal
-- como diretor_turma_id hoje (só se muda à mão no SQL Editor).
ALTER TABLE turma_diretores ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS turma_diretores_select ON turma_diretores;
CREATE POLICY turma_diretores_select ON turma_diretores
  FOR SELECT
  TO authenticated
  USING (public.is_current_user_professor());

DROP POLICY IF EXISTS turma_diretores_admin_all ON turma_diretores;
CREATE POLICY turma_diretores_admin_all ON turma_diretores
  FOR ALL
  TO authenticated
  USING (public.is_current_user_admin())
  WITH CHECK (public.is_current_user_admin());

COMMIT;
