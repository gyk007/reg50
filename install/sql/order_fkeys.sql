BEGIN;

ALTER TABLE order_document DROP CONSTRAINT IF EXISTS order_document_id_order_fkey;
ALTER TABLE order_document ADD CONSTRAINT order_document_id_order_fkey FOREIGN KEY (id_order) REFERENCES orders(id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE order_product DROP CONSTRAINT order_product_id_order_fkey;
ALTER TABLE order_product ADD CONSTRAINT order_product_id_order_fkey FOREIGN KEY (id_order) REFERENCES orders(id) ON DELETE CASCADE ON UPDATE CASCADE;

COMMIT;
