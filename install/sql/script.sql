BEGIN;
ALTER TABLE orders DROP COLUMN id_merchant;
DELETE FROM session;
DELETE FROM reg_session;
UPDATE merchant SET password = null, email = null, name = null, phone = null WHERE alkoid is NOT NULL;
COMMIT;