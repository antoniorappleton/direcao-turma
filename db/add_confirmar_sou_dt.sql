-- Self-service para "sou DT desta turma", a resolver logo no onboarding
-- (`minhas-turmas.html`, ao lado da seleção de turmas lecionadas) em vez de
-- precisar de um admin a corrigir `diretor_turma_id` à mão no SQL Editor
-- sempre que uma conta nova é criada (ver db/set_diretores_turma.sql e
-- db/set_diretores_turma_2.sql — este problema já aconteceu duas vezes).
--
-- Guarda de segurança: um professor só se consegue autoconfirmar DT de uma
-- turma se o seu nome (todas as palavras de professores.nome) aparecer no
-- texto já registado em turmas.diretor_turma — a mesma fonte "oficial"
-- (sincronizada do Scriptorium) que os scripts manuais até agora também
-- usavam para confirmar a correspondência. Não dá para um professor
-- qualquer autoproclamar-se DT de uma turma à toa. Admin não tem esta
-- restrição.
--
-- Se a turma ainda não tem DT principal (diretor_turma_id NULL), o
-- professor que confirma passa a ocupá-lo; se já tem (outro professor),
-- entra como DT adicional em turma_diretores (ver db/add_turma_diretores.sql
-- — dois DT em simultâneo). Retirar-se só é possível enquanto DT adicional;
-- tirar o DT principal continua a ser só por admin (evita ficar uma turma
-- sem nenhum DT por engano).
--
-- Execute no SQL Editor do Supabase, depois de db/add_turma_diretores.sql
-- (já deve ter corrido).

BEGIN;

CREATE OR REPLACE FUNCTION public.confirmar_sou_dt(p_turma_id uuid)
  RETURNS void
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path = public
  AS $$
  DECLARE
    v_professor_id uuid;
    v_nome_professor text;
    v_diretor_turma_id uuid;
    v_diretor_turma_texto text;
    v_palavra text;
  BEGIN
    SELECT id, nome INTO v_professor_id, v_nome_professor
    FROM public.professores
    WHERE lower(email) = lower(public.current_user_email());

    IF v_professor_id IS NULL THEN
      RAISE EXCEPTION 'Professor não encontrado.';
    END IF;

    SELECT diretor_turma_id, diretor_turma INTO v_diretor_turma_id, v_diretor_turma_texto
    FROM public.turmas WHERE id = p_turma_id;

    IF v_diretor_turma_id = v_professor_id THEN
      RETURN; -- já é o DT principal desta turma, nada a fazer
    END IF;

    IF NOT public.is_current_user_admin() THEN
      IF v_diretor_turma_texto IS NULL OR trim(v_diretor_turma_texto) = '' THEN
        RAISE EXCEPTION 'Esta turma não tem DT registado — pede à administração para confirmar.';
      END IF;

      FOREACH v_palavra IN ARRAY string_to_array(trim(v_nome_professor), ' ')
      LOOP
        IF v_palavra <> '' AND v_diretor_turma_texto NOT ILIKE '%' || v_palavra || '%' THEN
          RAISE EXCEPTION 'O teu nome (%) não corresponde ao DT registado para esta turma (%) — pede à administração para confirmar.',
            v_nome_professor, v_diretor_turma_texto;
        END IF;
      END LOOP;
    END IF;

    IF v_diretor_turma_id IS NULL THEN
      UPDATE public.turmas SET diretor_turma_id = v_professor_id WHERE id = p_turma_id;
    ELSE
      INSERT INTO public.turma_diretores (turma_id, professor_id)
      VALUES (p_turma_id, v_professor_id)
      ON CONFLICT DO NOTHING;
    END IF;
  END;
  $$;

GRANT EXECUTE ON FUNCTION public.confirmar_sou_dt(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.retirar_me_dt(p_turma_id uuid)
  RETURNS void
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path = public
  AS $$
  DECLARE
    v_professor_id uuid;
    v_diretor_turma_id uuid;
  BEGIN
    SELECT id INTO v_professor_id FROM public.professores WHERE lower(email) = lower(public.current_user_email());

    SELECT diretor_turma_id INTO v_diretor_turma_id FROM public.turmas WHERE id = p_turma_id;

    IF v_diretor_turma_id = v_professor_id AND NOT public.is_current_user_admin() THEN
      RAISE EXCEPTION 'Esta turma tem-te como DT principal — pede à administração para alterar.';
    END IF;

    DELETE FROM public.turma_diretores WHERE turma_id = p_turma_id AND professor_id = v_professor_id;
  END;
  $$;

GRANT EXECUTE ON FUNCTION public.retirar_me_dt(uuid) TO authenticated;

COMMIT;
