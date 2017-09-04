-- Производители, бренды
-- step 0007
-- class:
--    ALKO::Catalog::Manufacturer
--    ALKO::Catalog::Brand

BEGIN;


CREATE TABLE manufacturer (
    id          SERIAL,
    name        VARCHAR(128) NOT NULL DEFAULT 'UNKNOWN',
    description VARCHAR(4096),
    PRIMARY KEY (id)
);

GRANT SELECT, UPDATE         ON SEQUENCE manufacturer_id_seq TO @@DBUSER@@;
GRANT SELECT, UPDATE, INSERT ON TABLE    manufacturer        TO @@DBUSER@@;

COMMENT ON TABLE  manufacturer             IS 'производители';
COMMENT ON COLUMN manufacturer.id          IS 'id';
COMMENT ON COLUMN manufacturer.name        IS 'наименование';
COMMENT ON COLUMN manufacturer.description IS 'описание';


CREATE TABLE brand (
    id              SERIAL,
    id_manufacturer INTEGER REFERENCES manufacturer(id) ON UPDATE CASCADE,
    name            VARCHAR(128) NOT NULL DEFAULT 'UNKNOWN',
    description     VARCHAR(4096),
    PRIMARY KEY (id)
);

GRANT SELECT, UPDATE         ON SEQUENCE brand_id_seq TO @@DBUSER@@;
GRANT SELECT, UPDATE, INSERT ON TABLE    brand        TO @@DBUSER@@;

COMMENT ON TABLE  brand                 IS 'бренд, товарная марка';
COMMENT ON COLUMN brand.id              IS 'id';
COMMENT ON COLUMN brand.id_manufacturer IS 'производитель владелец бренда';
COMMENT ON COLUMN brand.name            IS 'наименование';
COMMENT ON COLUMN brand.description     IS 'описание';


COMMIT;
