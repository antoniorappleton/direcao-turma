-- Campos adicionais na ficha do Encarregado de Educação: estado civil e
-- situação profissional (como checkboxes independentes, não mutuamente
-- exclusivos na BD — a validação de "só um dos dois" fica para a UI) e notas
-- livres.

BEGIN;

ALTER TABLE encarregados ADD COLUMN IF NOT EXISTS casado boolean DEFAULT false;
ALTER TABLE encarregados ADD COLUMN IF NOT EXISTS divorciado boolean DEFAULT false;
ALTER TABLE encarregados ADD COLUMN IF NOT EXISTS empregado boolean DEFAULT false;
ALTER TABLE encarregados ADD COLUMN IF NOT EXISTS desempregado boolean DEFAULT false;
ALTER TABLE encarregados ADD COLUMN IF NOT EXISTS notas text;

COMMIT;
