BEGIN;

ALTER TABLE orders ADD alko_sync_status boolean DEFAULT 'f';

COMMENT ON COLUMN orders.alko_sync_status IS 'Статус синхронизации заказа с системой заказчика';

COMMIT;