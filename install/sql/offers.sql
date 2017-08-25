-- Индивидуальные предложения
-- step 019
-- class: ALKO::Client::Offer

BEGIN;

-- создаем тип скидки
CREATE TYPE offer_type AS ENUM ('percent','rub');
COMMENT ON TYPE  offer_type IS 'тип скидки; percent - скидка в процентах; rub - рублях';

-- таблица индивидуальных предложений
CREATE TABLE offer (
    id_merchant INTEGER REFERENCES merchant(id),
    id_product  INTEGER REFERENCES product(id),
    type        offers_type,
    value       DECIMAL(10, 2) CHECK (value >= 0),

    PRIMARY KEY (id_merchant, id_product)
);

GRANT SELECT, UPDATE, DELETE, INSERT ON TABLE offer TO @@DBUSER@@;

COMMENT ON TABLE  offer             IS 'индивидуальное предложение';
COMMENT ON COLUMN offer.id_merchant IS 'представитль';
COMMENT ON COLUMN offer.id_product  IS 'товар';
COMMENT ON COLUMN offer.type        IS 'тип скидки';
COMMENT ON COLUMN offer.value       IS 'значение скидки';

COMMIT;