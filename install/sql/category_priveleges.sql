-- Выдача прав юзеру на удаление категорий
-- step 0008


BEGIN;


GRANT SELECT, UPDATE, INSERT ON TABLE category       TO @@DBUSER@@;
GRANT SELECT, UPDATE, INSERT ON TABLE category_graph TO @@DBUSER@@;


COMMIT;
