-- Начальный набор глоальных свойств, соответствующих исходному каталогу
-- step 0011

BEGIN;


-- убрать тип свойства 'Integer'
DELETE FROM matrixnode     WHERE down = 1;
DELETE FROM matrix         WHERE nextdown = 2;
DELETE FROM unitvalue      WHERE down = 1;
DELETE FROM matrixunit     WHERE down = 1;
DELETE FROM proptype_graph WHERE down = 2;
DELETE FROM proptype       WHERE id = 2;


-- заменить тип значения на класс движка
ALTER TABLE proptype DROP COLUMN valtype;
DROP TYPE propval_t;

ALTER TABLE proptype ADD COLUMN CLASS VARCHAR(64);
COMMENT ON COLUMN proptype.class IS 'имя класса в либе ALKO::Catalog::Property::Type::Engine::*';

UPDATE proptype SET class = 'Scalar'           WHERE id = 1;
UPDATE proptype SET class = 'Select::UniTable' WHERE id = 4;

-- добавить главную группу свойств и привязать ее к корню каталога
INSERT INTO propgroup (id, name, face, description) VALUES (default, 'main', null, null);
INSERT INTO grouplink (id_category, id_propgroup, face, weight, visible, joint) VALUES (0, 1, null, 10, true, false);


-- добавить свойства
INSERT INTO property VALUES (1, 1, 1, 'Price', null, null, 'price', true);
INSERT INTO property VALUES (1, 2, 4, 'Brand', null, null, 'brand', true);


-- добавить в справочники ид заказчика
ALTER TABLE manufacturer ADD COLUMN alkoid VARCHAR(64) UNIQUE;
ALTER TABLE brand        ADD COLUMN alkoid varchar(64) UNIQUE;

COMMENT ON COLUMN manufacturer.alkoid IS 'alko id - идентификатор во внешней системе';
COMMENT ON COLUMN brand.alkoid bp       IS 'alko id - идентификатор во внешней системе';


-- имена параметров типа должны быть уникальны, чтобы можно было обращаться к ним по именам
ALTER TABLE propparam ADD UNIQUE (id_proptype, name);


-- параметр для выборки из таблицы указанного класса
INSERT INTO propparam (id_proptype, n, name, description) VALUES (4, 1, 'source', 'Class name');

INSERT INTO paramvalue (id_propgroup, n_propgroup, id_proptype, n, value) VALUES (1, 2, 4, 1, 'ALKO::Catalog::Brand');


-- свойство "Производитель"
INSERT INTO property (id_propgroup, n, id_proptype, name, visible) VALUES (1, 3, 4, 'Manufacturer', true);

INSERT INTO paramvalue (id_propgroup, n_propgroup, id_proptype, n, value) VALUES (1, 3, 4, 1, 'ALKO::Catalog::Manufacturer');


-- тип хранимого значения в скаляре
INSERT INTO propparam (id_proptype, n, name, description) VALUES (1, 1, 'store', 'Stored type: integer, float');

INSERT INTO paramvalue (id_propgroup, n_propgroup, id_proptype, n, value) VALUES (1, 1, 1, 1, 'integer');


-- литраж, крепость, упаковка
INSERT INTO property (id_propgroup, n, id_proptype, name, visible) VALUES (1, 4, 1, 'Litr', true);
INSERT INTO property (id_propgroup, n, id_proptype, name, visible) VALUES (1, 5, 1, 'Alko', true);
INSERT INTO property (id_propgroup, n, id_proptype, name, visible) VALUES (1, 6, 1, 'Pack', true);

INSERT INTO paramvalue (id_propgroup, n_propgroup, id_proptype, n, value) VALUES (1, 4, 1, 1, 'float');
INSERT INTO paramvalue (id_propgroup, n_propgroup, id_proptype, n, value) VALUES (1, 5, 1, 1, 'float');
INSERT INTO paramvalue (id_propgroup, n_propgroup, id_proptype, n, value) VALUES (1, 6, 1, 1, 'integer');


-- свойство "Страна-производитель"
CREATE TABLE country (
	id   SERIAL,
	name VARCHAR(256),
	PRIMARY KEY (id)
);

COMMENT ON TABLE country IS 'Страна';

GRANT SELECT, UPDATE, INSERT ON TABLE country TO @@DBUSER@@;

INSERT INTO property (id_propgroup, n, id_proptype, name, visible) VALUES (1, 7, 4, 'Made in', true);
INSERT INTO paramvalue (id_propgroup, n_propgroup, id_proptype, n, value) VALUES (1, 7, 4, 1, 'ALKO::Country');


-- сущность больше не является последовательностью
ALTER TABLE paramvalue RENAME COLUMN n TO n_proptype;


COMMIT;
