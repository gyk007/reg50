BEGIN;

create or replace view v_shop as
select 
    o.id            as official_id,
    o.id_file       as official_id_file,
    o.name          as official_name,
    o.address       as official_address,
    o.regaddress    as official_regaddress,
    o.phone         as official_phone,
    o.email         as official_email,
    o.bank          as official_bank,
    o.account       as official_account,
    o.bank_account  as official_bank_account,
    o.bik           as official_bik,
    o.taxcode       as official_taxcode,
    o.taxreasoncode as official_taxreasoncode,
    o.regcode       as official_regcode,
    o.alkoid        as official_alkoid,
    o.person        as official_person,
    m.id            as merchant_id,
    m.password      as merchant_password,
    m.email         as merchant_email,
    m.name          as merchant_name,
    m.phone         as merchant_phone,
    m.alkoid        as merchant_alkoid,
    n.id            as net_id,
    s.id            as shop_id
from shop s 
      inner join official o 
        on s.id_official = o.id 
      inner join merchant m 
        on s.id_merchant = m.id 
      inner join net n 
        on s.id_net = n.id;    

COMMIT;
