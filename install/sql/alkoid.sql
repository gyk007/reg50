-- Добавляем ид заказчика
-- step 0016

BEGIN;

-- добавить ид заказчика
ALTER TABLE merchant ADD COLUMN alkoid VARCHAR(64) UNIQUE;
ALTER TABLE official ADD COLUMN alkoid VARCHAR(64) UNIQUE;

-- удаляем ограничение UNIQUE
ALTER TABLE official DROP CONSTRAINT official_taxcode_key;

COMMIT;