-- Корректирование уникальности полей
-- step 0010

BEGIN;


ALTER TABLE category_graph DROP CONSTRAINT ichild;
ALTER TABLE category_graph ADD UNIQUE (top, sortn);


COMMIT;

