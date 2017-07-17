-- Параметры типов свойств и их значения для каждого параметра
-- step 0008
-- class:
--    ALKO::Catalog::Property::Type::Param
--    ALKO::Catalog::Property::Type::Param::Value

BEGIN;


CREATE TABLE propparam (
	id_proptype INTEGER REFERENCES proptype(id) ON UPDATE CASCADE,
	n           INTEGER,
        name        VARCHAR(256) NOT NULL,
        description VARCHAR(4096),
        PRIMARY KEY (id_proptype, n)
);

GRANT SELECT, UPDATE, INSERT ON TABLE propparam TO @@DBUSER@@;

COMMENT ON TABLE  propparam             IS 'параметры типов свойств';
COMMENT ON COLUMN propparam.id_proptype IS 'тип, к которому относится параметр';
COMMENT ON COLUMN propparam.n           IS 'индекс параметра внутри типа; начинается с 1';
COMMENT ON COLUMN propparam.name        IS 'наименование';
COMMENT ON COLUMN propparam.description IS 'описание';


ALTER TABLE property ADD UNIQUE (id_propgroup, n, id_proptype);


CREATE TABLE paramvalue (
	id_propgroup INTEGER,
	n_propgroup  INTEGER,
	id_proptype  INTEGER,
	n            INTEGER,
        value        VARCHAR(64),
        FOREIGN KEY (id_propgroup, n_propgroup, id_proptype) REFERENCES property(id_propgroup, n, id_proptype) ON UPDATE CASCADE,
        FOREIGN KEY (id_proptype, n) REFERENCES propparam(id_proptype, n),
        PRIMARY KEY (id_propgroup, n_propgroup, n)
);

GRANT SELECT, UPDATE, INSERT ON TABLE paramvalue TO @@DBUSER@@;

COMMENT ON TABLE  paramvalue              IS 'значения параметров типов свойств для конкретного типа';
COMMENT ON COLUMN paramvalue.id_propgroup IS 'группа свойства; составная часть идентификатора свойства';
COMMENT ON COLUMN paramvalue.n_propgroup  IS 'индекс свойства в группе; составная часть идентификатора свойства';
COMMENT ON COLUMN paramvalue.id_proptype  IS 'тип свойства; избыточен, т.к. определяется свойством, но обеспечивает целостность';
COMMENT ON COLUMN paramvalue.n            IS 'индекс параметра внутри типа';
COMMENT ON COLUMN paramvalue.value        IS 'фактическое значение для конкретного типа';


COMMIT;
