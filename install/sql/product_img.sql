BEGIN;


-- добавляем поля для картинок
ALTER TABLE product ADD COLUMN img_small  VARCHAR(64);
ALTER TABLE product ADD COLUMN img_medium VARCHAR(64);
ALTER TABLE product ADD COLUMN img_big    VARCHAR(64);

COMMENT ON COLUMN product.img_small   IS 'маленькая картинка';
COMMENT ON COLUMN product.img_medium  IS 'средняя картинка';
COMMENT ON COLUMN product.img_big     IS 'большая картинка';

-- добавляем поле taxcode для фалов
ALTER TABLE file ADD COLUMN taxcode  VARCHAR(64);

COMMENT ON COLUMN file.taxcode IS 'ИНН организации которй пренадлежит файл';

-- удаляем поле receivables - задолженность
ALTER TABLE orders DROP COLUMN receivables;

-- добавляем поле debt - дебиторская задолженность
ALTER TABLE orders ADD COLUMN debt DECIMAL(10, 2);

COMMENT ON COLUMN orders.debt IS 'дебиторская задолженность';


COMMIT;