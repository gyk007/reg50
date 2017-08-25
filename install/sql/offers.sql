-- Сессии
-- step 019
-- class: ALKO::Client::Offers

BEGIN;

-- создаем тип скидки
CREATE TYPE offer_type AS ENUM ('percent','rub');
COMMENT ON TYPE  document_status IS 'тип скидки; percent - скидка в процентах; rub - рублях';

-- таблица индивидуальных предложений
CREATE TABLE offer (
    id_merchant INTEGER REFERENCES merchant(id),
    id_product  INTEGER REFERENCES product(id),
    type        offers_type,
    value       DECIMAL(10, 2) CHECK (value >= 0),

    PRIMARY KEY (id_merchant, id_product)
);

GRANT SELECT, UPDATE, DELETE, INSERT ON TABLE session TO @@DBUSER@@;

COMMENT ON TABLE  offers             IS 'индивидуальное предложение';
COMMENT ON COLUMN offers.id_merchant IS 'представитль';
COMMENT ON COLUMN offers.id_product  IS 'товар';
COMMENT ON COLUMN offers.type        IS 'тип скидки';
COMMENT ON COLUMN offers.value       IS 'значение скидки';

COMMIT;