-- Domínios de avaliação intercalar (Saber Ser / Saber Fazer / Saber Saber),
-- usados pelo relatório de Avaliação Intercalar e pela importação em massa a
-- partir de Excel (ver app/js/utils/importar-avaliacoes.js). Só se aplicam a
-- avaliações com tipo = 'intercalar' — nos restantes tipos ficam a null.
--
-- Aditivo: não altera nada existente em `avaliacoes` (ver db/add_avaliacoes.sql).
--
-- Execute este ficheiro no SQL Editor do Supabase.

BEGIN;

ALTER TABLE avaliacoes
  ADD COLUMN IF NOT EXISTS saber_ser numeric(5, 2),
  ADD COLUMN IF NOT EXISTS saber_fazer numeric(5, 2),
  ADD COLUMN IF NOT EXISTS saber_saber numeric(5, 2);

COMMIT;
