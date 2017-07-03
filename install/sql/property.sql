-- Cвойства товара
-- step 0006
-- class: ALKO::Catalog::Property,
--        ALKO::Catalog::Property::Type,
--        ALKO::Catalog::Property::Value,

BEGIN;


-- типы свойств
CREATE TYPE PROPVAL_T AS ENUM ('val_int', 'val_bool', 'val_float', 'val_char', 'val_time');

CREATE TABLE proptype (
	id          SERIAL,
	name        VARCHAR(128) NOT NULL UNIQUE,
	description VARCHAR(4096),
	valtype     PROPVAL_T,
	PRIMARY KEY (id)
);

GRANT SELECT, UPDATE         ON SEQUENCE proptype_id_seq TO @@DBUSER@@;
GRANT SELECT, UPDATE, INSERT ON TABLE    proptype        TO @@DBUSER@@;

COMMENT ON TABLE  proptype             IS 'тип свойства';
COMMENT ON COLUMN proptype.id          IS 'id';
COMMENT ON COLUMN proptype.name        IS 'наименование типа на русском';
COMMENT ON COLUMN proptype.description IS 'описание';
COMMENT ON COLUMN proptype.valtype     IS 'тип хранимого данным типом свойства значения; у разных типов свойств типы значения могут быть одинаковыми';


-- свойства
CREATE TABLE property (
	id_propgroup INTEGER REFERENCES propgroup(id) ON UPDATE CASCADE,
	n            INTEGER,
	id_proptype  INTEGER NOT NULL REFERENCES proptype(id) ON UPDATE CASCADE,
	name         VARCHAR(256) NOT NULL,
	face         VARCHAR(512),
	description  VARCHAR(4096),
	const        VARCHAR(32) UNIQUE,
	visible      BOOLEAN NOT NULL DEFAULT FALSE,
	UNIQUE (id_propgroup, name),
	UNIQUE (id_propgroup, face),
	PRIMARY KEY (id_propgroup, n)
);

GRANT SELECT, UPDATE, INSERT ON TABLE    property        TO @@DBUSER@@;

COMMENT ON TABLE  property              IS 'размещение групп свойств по категориям; одна группа во многих категориях';
COMMENT ON COLUMN property.id_propgroup IS 'свойство однозначно принадлежит Группе Свойств';
COMMENT ON COLUMN property.n            IS 'порядковый номер свойства в своей группе';
COMMENT ON COLUMN property.id_proptype  IS 'свойство имеет определенный тип';
COMMENT ON COLUMN property.name         IS 'имя для админки';
COMMENT ON COLUMN property.face         IS 'имя для вывода; переопределяет name';
COMMENT ON COLUMN property.description  IS 'полное опиание';
COMMENT ON COLUMN property.const        IS 'короткое имя на английском для обращения из кода к постоянным свойствам';
COMMENT ON COLUMN property.visible      IS 'выводить ли свойство в каталог';


-- Фактические значения свойств
CREATE TABLE propvalue (
	id_product   INTEGER REFERENCES product(id)  ON UPDATE CASCADE,
	id_propgroup INTEGER,
	n_property   INTEGER,
	val_int      INTEGER,
	val_bool     BOOLEAN,
	val_float    FLOAT,
	val_char     VARCHAR(1024),
	val_time     TIMESTAMP(6) WITH TIME ZONE,
	FOREIGN KEY (id_propgroup, n_property) REFERENCES property(id_propgroup, n) ON UPDATE CASCADE,
	PRIMARY KEY (id_product, id_propgroup, n_property)
);

GRANT SELECT, UPDATE, INSERT ON TABLE propvalue TO @@DBUSER@@;

COMMENT ON TABLE  propvalue              IS 'фактические значения свойств для каждого товара';
COMMENT ON COLUMN propvalue.id_product   IS 'товар';
COMMENT ON COLUMN propvalue.id_propgroup IS 'группа свойств свойства';
COMMENT ON COLUMN propvalue.n_property   IS 'порядковый номер свойства в группе свойств';
COMMENT ON COLUMN propvalue.val_int      IS 'целое';
COMMENT ON COLUMN propvalue.val_bool     IS 'логическое';
COMMENT ON COLUMN propvalue.val_float    IS 'вещественное';
COMMENT ON COLUMN propvalue.val_char     IS 'строки';
COMMENT ON COLUMN propvalue.val_time     IS 'дата/время';


COMMIT;
