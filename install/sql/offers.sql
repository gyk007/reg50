-- Индивидуальные предложения
-- step 019
-- class: ALKO::Client::Offer

BEGIN;

-- создаем тип скидки
CREATE TYPE offer_type AS ENUM ('percent','rub');
COMMENT ON TYPE  offer_type IS 'тип скидки; percent - скидка в процентах; rub - рублях';

-- таблица индивидуальных предложений
CREATE TABLE offer (
    id         SERIAL,
    id_shop    INTEGER REFERENCES shop(id),
    id_product INTEGER REFERENCES product(id),
    type       offers_type,
    value      DECIMAL(10, 2),
    ctime      TIMESTAMP(6) WITH TIME ZONE,

    PRIMARY KEY (id)
);

GRANT SELECT, UPDATE, DELETE, INSERT ON TABLE offer TO @@DBUSER@@;

COMMENT ON TABLE  offer             IS 'индивидуальное предложение';
COMMENT ON COLUMN offer.id          IS 'ид';
COMMENT ON COLUMN offer.id_shop     IS 'торговая точка';
COMMENT ON COLUMN offer.id_product  IS 'товар';
COMMENT ON COLUMN offer.type        IS 'тип скидки';
COMMENT ON COLUMN offer.value       IS 'значение скидки';
COMMENT ON COLUMN offer.ctime       IS 'дата создания';

COMMIT;49761 74893