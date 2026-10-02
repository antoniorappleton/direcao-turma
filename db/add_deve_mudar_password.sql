-- Obriga qualquer professor a definir a sua própria palavra-passe antes de
-- usar a app — ver app/js/core/auth.js (defaultPasswordFor) e
-- app/mudar-password.html. Substitui a antiga password partilhada única
-- ("P@ssword") por uma password por omissão individual, só válida na
-- primeira entrada: [apelido],csj2026 (ex: antonio.appleton@... ->
-- "appleton,csj2026").
--
-- Aditivo: só acrescenta uma coluna e uma função RPC — não altera nem apaga
-- nada existente em `professores` (tabela partilhada com o Scriptorium).
--
-- Execute este ficheiro no SQL Editor do Supabase. Depois de correr, usa
-- scripts/reset_teacher_passwords.ps1 para repor a password das contas já
-- existentes (hoje todas na antiga password partilhada) para o novo padrão.

BEGIN;

ALTER TABLE professores
  ADD COLUMN IF NOT EXISTS deve_mudar_password boolean NOT NULL DEFAULT true;

-- Força TODOS os professores já existentes a passar pelo ecrã de mudança
-- pelo menos uma vez — até agora ninguém tinha password própria.
UPDATE professores SET deve_mudar_password = true;

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

-- RPC estreita em vez de uma política de UPDATE genérica: um professor só
-- pode limpar a SUA PRÓPRIA flag, nunca mudar role/nome/email de ninguém
-- (isso continua reservado a admins/service_role) — ver
-- app/mudar-password.html, que chama isto via supabase.rpc(...).
CREATE OR REPLACE FUNCTION public.marcar_password_mudada()
  RETURNS void
  LANGUAGE sql
  SECURITY DEFINER
  SET search_path = public
  AS $$
    UPDATE professores
    SET deve_mudar_password = false
    WHERE lower(email) = lower(public.current_user_email())
  $$;

GRANT EXECUTE ON FUNCTION public.marcar_password_mudada() TO authenticated;

COMMIT;
