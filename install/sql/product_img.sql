-- добавляем поля для картинок
ALTER TABLE product ADD COLUMN img_small  VARCHAR(64);
ALTER TABLE product ADD COLUMN img_medium VARCHAR(64);
ALTER TABLE product ADD COLUMN img_big    VARCHAR(64);

-- добавляем поле taxcode для фалов
ALTER TABLE file ADD COLUMN taxcode  VARCHAR(64);