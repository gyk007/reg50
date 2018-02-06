BEGIN;

INSERT INTO order_status (id, name, description) VALUES (default, 'deleted', 'Удален');

COMMIT;