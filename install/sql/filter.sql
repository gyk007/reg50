-- Фильтры
-- step 0013
-- class:
-- ALKO::Catalog::Filter::UI
-- ALKO::Catalog::Filter::Arg
-- ALKO::Catalog::Filter::Arg::PropLink

BEGIN;


-- тип пользовательского интерфейса фильтра
CREATE TABLE filterui (
        id          SERIAL,
        name        VARCHAR(32) NOT NULL UNIQUE,
        description VARCHAR(4096),
        PRIMARY KEY (id)
);

GRANT SELECT, UPDATE         ON SEQUENCE filterui_id_seq TO @@DBUSER@@;
GRANT SELECT, UPDATE, INSERT ON TABLE    filterui        TO @@DBUSER@@;

COMMENT ON TABLE  filterui             IS 'тип представления фильтра пользователю';
COMMENT ON COLUMN filterui.id          IS 'id';
COMMENT ON COLUMN filterui.name        IS 'наименование; короткое имя для ссылки из кода';
COMMENT ON COLUMN filterui.description IS 'описание';


-- аргументы, определяющие выборку
CREATE TABLE filterarg (
        id          SERIAL,
        name        VARCHAR(32) NOT NULL UNIQUE,
        description VARCHAR(4096),
        PRIMARY KEY (id)
);

GRANT SELECT, UPDATE         ON SEQUENCE filterarg_id_seq TO @@DBUSER@@;
GRANT SELECT, UPDATE, INSERT ON TABLE    filterarg        TO @@DBUSER@@;

COMMENT ON TABLE  filterarg             IS 'аргументы фильтра задают выборку';
COMMENT ON COLUMN filterarg.id          IS 'id';
COMMENT ON COLUMN filterarg.name        IS 'наименование; короткое имя для ссылки из кода';
COMMENT ON COLUMN filterarg.description IS 'описание';


-- аргументы фильтра необходимые конкретному свойству
CREATE TABLE filterarg_link (
	id_propgroup INTEGER,
	n_property   INTEGER,
	id_filterarg INTEGER REFERENCES filterarg(id),
	FOREIGN KEY (id_propgroup, n_property) REFERENCES property(id_propgroup, n),
        PRIMARY KEY (id_propgroup, n_property, id_filterarg)
);

GRANT SELECT, UPDATE, INSERT ON TABLE filterarg_link TO @@DBUSER@@;

COMMENT ON TABLE  filterarg_link              IS 'аргументы фильтра необходимые конкретному свойству';
COMMENT ON COLUMN filterarg_link.id_propgroup IS 'группа свойств от ключа Свойства';
COMMENT ON COLUMN filterarg_link.n_property   IS 'номер свойства в группе от ключа Свойства';
COMMENT ON COLUMN filterarg_link.id_filterarg IS 'один из конкретных аргументов фильтра';


-- назначить свойству фильтр и добавить выключатель
ALTER TABLE property ADD COLUMN filters     BOOLEAN;
ALTER TABLE property ADD COLUMN id_filterui INTEGER REFERENCES filterui(id);

COMMENT ON COLUMN property.filters     IS 'выводить фильтр пользователю';
COMMENT ON COLUMN property.id_filterui IS 'виджет представления фильтра на клиенте';


-- фильтр для Price
INSERT INTO filterui  (id, name, description) VALUES (default, 'hslider', 'Horizontal slider widget');  -- id=1

INSERT INTO filterarg (id, name, description) VALUES (default, 'min', 'Minumum value available');       -- id=1
INSERT INTO filterarg (id, name, description) VALUES (default, 'max', 'Maximum value available');       -- id=2

INSERT INTO filterarg_link (id_propgroup, n_property, id_filterarg) VALUES (1, 1, 1);
INSERT INTO filterarg_link (id_propgroup, n_property, id_filterarg) VALUES (1, 1, 2);

UPDATE property SET filters = TRUE, id_filterui = 1 WHERE id_propgroup = 1 AND n = 1;


COMMIT;
