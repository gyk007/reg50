-- добавляем поле debt - дебиторская задолженность
ALTER TABLE orders ADD COLUMN debt DECIMAL(10, 2);

COMMENT ON COLUMN orders.debt IS 'дебиторская задолженность';
