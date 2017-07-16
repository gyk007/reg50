-- Выдача прав юзеру на удаление категорий
-- step 0008


BEGIN;


GRANT DELETE ON TABLE category       TO @@DBUSER@@;
GRANT DELETE ON TABLE category_graph TO @@DBUSER@@;


COMMIT;
