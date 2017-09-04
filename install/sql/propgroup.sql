-- Группы свойств
-- step 0005
-- class: ALKO::Catalog::Property::Group,
--        ALKO::Catalog::Property::Group::Link

BEGIN;


-- группы
CREATE TABLE propgroup (
	id          SERIAL,
	name        VARCHAR(1024) NOT NULL DEFAULT 'UNKNOWN',
	face        VARCHAR(1024),
	description VARCHAR(4096),
	PRIMARY KEY (id)
);

GRANT SELECT, UPDATE         ON SEQUENCE propgroup_id_seq TO @@DBUSER@@;
GRANT SELECT, UPDATE, INSERT ON TABLE    propgroup        TO @@DBUSER@@;

COMMENT ON TABLE  propgroup             IS 'группа свойств';
COMMENT ON COLUMN propgroup.id          IS 'id';
COMMENT ON COLUMN propgroup.name        IS 'наименование';
COMMENT ON COLUMN propgroup.face        IS 'наименование, выводимое в каталоге';
COMMENT ON COLUMN propgroup.description IS 'описание';


-- принадлежность групп категориям
CREATE TABLE grouplink (
	id_category  INTEGER REFERENCES category(id)  ON UPDATE CASCADE,
	id_propgroup INTEGER REFERENCES propgroup(id) ON UPDATE CASCADE,
	face         VARCHAR(1024),
	weight       INTEGER NOT NULL DEFAULT 1,
	visible      BOOLEAN NOT NULL DEFAULT FALSE,
	joint        BOOLEAN NOT NULL DEFAULT FALSE,
	UNIQUE (id_category, face), -- не должно быть в одной категории одинаковых групп
	PRIMARY KEY (id_category, id_propgroup)
);

GRANT SELECT, UPDATE, INSERT ON TABLE grouplink TO @@DBUSER@@;

COMMENT ON TABLE  grouplink              IS 'размещение групп свойств по категориям; одна группа во многих категориях';
COMMENT ON COLUMN grouplink.id_category  IS 'категория каталога';
COMMENT ON COLUMN grouplink.id_propgroup IS 'группа свойств';
COMMENT ON COLUMN grouplink.face         IS 'отображение наименования группы в конкретной категории';
COMMENT ON COLUMN grouplink.weight       IS 'вес сортировки; больше вес - ниже в выдаче';
COMMENT ON COLUMN grouplink.visible      IS 'выводить ли группу и все ее свойства пользователю';
COMMENT ON COLUMN grouplink.joint        IS 'поместить ли группу в виртуальную общую группу категории; группа не обособляется, заголовок не выводится';


COMMIT;
