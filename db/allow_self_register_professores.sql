-- Permite o auto-registo de professores: o login de direcao-turma passa a
-- aceitar qualquer email nome.apelido@colegio-ramalhao.com com a palavra-
-- passe partilhada pela escola, criando a conta Supabase Auth (signUp) e a
-- respetiva linha em `professores` na primeira vez que alguém entra (ver
-- app/js/core/auth.js). Sem esta política, o INSERT dessa linha falhava
-- por RLS para qualquer professor que não fosse admin.
--
-- Aditivo: só adiciona uma política de INSERT (cada professor só pode
-- criar a linha com o SEU PRÓPRIO email) e garante leitura para
-- utilizadores autenticados — não mexe em políticas de UPDATE/DELETE que
-- já existam.
--
-- Execute este ficheiro no SQL Editor do Supabase.

BEGIN;

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

ALTER TABLE professores ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS authenticated_select_professores ON professores;
CREATE POLICY authenticated_select_professores
  ON professores FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS self_insert_professor ON professores;
CREATE POLICY self_insert_professor
  ON professores FOR INSERT
  TO authenticated
  WITH CHECK (lower(email) = lower(public.current_user_email()));

COMMIT;

-- Nota: isto NÃO toca em políticas de UPDATE/DELETE existentes (ex: gestão
-- de role por admins) — só garante que ler a lista de professores e criar a
-- própria linha funcionam para qualquer professor autenticado.
