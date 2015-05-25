header:set serveroutput off
header:set head off
header:set pagesize 0
header:set linesize 20000
header:set trimspool on
header:set trim on
header:set colsep ","
header:set termout off
header:set feedback off
header:set numwidth 15

alter session set nls_date_format = 'dd-Mon-yyyy hh24:mi:ss';
select 'ACCOUNT','SERVICE','BILL_PERIOD','PREV_CUTOFF_DATE','ACCOUNT_NO','SUBSCR_NO','SUBSCR_STATUS','OFFER_ID','DISPLAY_VALUE','PRIMARY_LIST_PRICE','FOREIGN_CODE','OFFER_TYPE','OFFER_INST_ID','CHG_WHO','CHG_DT','ACTIVE_DT','INACTIVE_DT','CANCELLED' from dual;

with lists1 as (select offer_id from offer_ref@cust1 oref, reseller_version@cust1 rv where oref.offer_type = 2 --and oref.equip_type_code = 101 
                          and rv.reseller_id = 7 and rv.inactive_date is null and rv.status in (3) and oref.reseller_version_id = rv.reseller_version_id and length(foreign_code) < 10
                          and exists (select 1 from offer_ref@cust1 where offer_type = 3 and offer_id = oref.offer_id-100000 and foreign_code = oref.foreign_code)),
rc_so as (select (select external_id from customer_id_acct_map@cust1 where account_no = oiv.parent_account_no and external_id_type = 1) ext_account, 
            oiv.parent_account_no, oiv.subscr_no, (select bill_period from cmf@cust1 where account_no = oiv.parent_account_no) as bill_period 
            from offer_inst_view@cust1 oiv, lists1 l
            where oiv.view_status = 2 and oiv.inactive_dt is null and oiv.offer_id = l.offer_id
            and not exists (select 1 from offer_inst_view@cust1 a where a.view_status = 2 and a.offer_id = oiv.offer_id-100000 and a.inactive_dt is null and a.subscr_no = oiv.subscr_no) 
            and exists (select 1 from subscriber_status@cust1 where subscr_no = oiv.subscr_no and status_id = 1 and inactive_dt is null)
), --Missing Discount SO
lists2 as (select offer_id from offer_ref@cust1 oref, reseller_version@cust1 rv where oref.offer_type = 2 and oref.equip_type_code in (101,1101) and oref.offer_id <> 102147
                          and rv.reseller_id = 7 and rv.inactive_date is null and rv.status in (3) and oref.reseller_version_id = rv.reseller_version_id and length(foreign_code) < 10
                          and exists (select 1 from offer_ref@cust1 where offer_type = 3 and offer_id = oref.offer_id+100000 and foreign_code = oref.foreign_code)),
disc_so as (select (select external_id from customer_id_acct_map@cust1 where account_no = oiv.parent_account_no and external_id_type = 1) ext_account,
                oiv.parent_account_no, oiv.subscr_no, (select bill_period from cmf@cust1 where account_no = oiv.parent_account_no) as bill_period  
                from offer_inst_view@cust1 oiv, lists2 l
                where oiv.view_status = 2 and oiv.inactive_dt is null and oiv.offer_id = l.offer_id
                and not exists (select 1 from offer_inst_view@cust1 a where a.view_status = 2 and a.offer_id = oiv.offer_id+100000 and a.inactive_dt is null and a.subscr_no = oiv.subscr_no) 
                and exists (select 1 from subscriber_status@cust1 where subscr_no = oiv.subscr_no and status_id = 1 and inactive_dt is null) 
), subscriberlist as (select distinct subscr_no from (select subscr_no from rc_so union select subscr_no from disc_so))
select distinct
(select distinct first_value(external_id) over (order by active_dt desc, inactive_dt desc nulls first) from customer_id_acct_map@cust1 where (account_no = b.account_no or account_no = b.parent_account_no) and is_current = 1 and external_id_type = 1) account, 
(select distinct first_value(external_id) over (order by active_date desc, inactive_date desc nulls first, external_id_type asc) from customer_id_equip_map_view@cust1 where subscr_no = b.subscr_no and view_status = 2 and external_id_type in (21,22,101,181,191,151,221)) service,
a.bill_period,  a.prev_cutoff_date, a.account_no, b.subscr_no,
(select sv.display_value from subscriber_status@cust1 ss, status_values@cust1 sv where ss.status_id = sv.status_id and ss.subscr_no = b.subscr_no and ss.inactive_dt is null) subscr_status,
b.offer_id, '"'||f.display_value||'"', f.primary_list_price, e.foreign_code, e.offer_type, b.offer_inst_id, b.chg_who, b.chg_dt, b.active_dt, b.inactive_dt,
decode(b.active_dt, b.inactive_dt, 'Cancelled', NULL)Cancelled 
from offer_inst_view@cust1 b, offer_ref@cust1 e, offer_values@cust1 f, reseller_version@cust1 g, cmf@cust1 a
where b.offer_id = e.offer_id and e.offer_id = f.offer_id and e.reseller_version_id = f.reseller_version_id and e.reseller_version_id = g.reseller_version_id
and g.reseller_id = 7 and g.inactive_date is null and g.status in (3) and b.view_status = 2
and ((a.account_no = b.account_no) or (a.account_no = b.parent_account_no))
--PO with missing Discount SO
and f.primary_list_price = 'BP' 
and exists (select 1 from subscriberlist where subscr_no = b.subscr_no)
order by a.bill_period, a.account_no, b.subscr_no, e.offer_type, case when to_char(b.offer_id) = foreign_code then 1 else 2 end, b.active_dt,b.inactive_dt;

with missing_disc as (
SELECT distinct
ciem1.subscr_no--, ciem1.external_id external_id_to, ov1.display_value display_value_to, ciem1.active_date, ciem2.external_id external_id_from, ov2.display_value display_value_from, 
--ss.parent_account_no, c.bill_period, c.next_bill_date
FROM customer_id_equip_map_view@cust1 ciem1, customer_id_equip_map_view@cust1 ciem2--, subscriber_view@cust1 ss, cmf@cust1 c, offer_values@cust1 ov1, offer_values@cust1 ov2
WHERE ciem1.external_id IN (
'115009','115035','115043','115090','115061','115122','115015','115028','115095','115107','115093','115092','115116','115010','115034','115044','102100','115052','115106','115091','115046',
'115060','115062','115117','115125','115008','115016','115029','115036','102037','115054','115123','115017','115023','115104','115124','115105','115094','115103','115007','115018','115042',
'115045','102506','115102','115053','115114','115115','102131','102231','102232','102016','102034','102035','102047','102086','102071','102201','102245','102260','102240','102285','102295',
'102015','102018','102025','102057','102061','102070','102082','102092','102202','102284','102013','102017','102019','102020','102021','102026','102048','102065','102085','115037','102198',
'102220','102227','102229','102283','102286','102014','102046','102087','102054','102055','102060','102064','102066','102072','102080','102075','102083','115032','102197','102218','102244',
'102293','102050','102053','102073','102076','102093','115025','102200','102261','102239','102294','102022','102023','102049','102045','102078','102219','102246','102228','102259','102230',
'102216','102062','102079','102081','115080','102199','102249','102051','102044','102063','102069','102074','102077','102084','115003','115004','115005','102091','115047','115048','115006',
'115002','115039','115070','115001','102259','102260','102261','102227','102228','102229','102230','102231','102232','102283','102284','102285','102286','102239','102240','102020','102021',
'102022','102023','102018','102019','102025','102026','102042','102043','102056','102058','102116','102233','102234','102236')
AND ciem1.external_id_type = 91 AND ciem1.view_status = 2 AND ciem1.active_date > To_Date('24-Feb-2015','dd-mon-yyyy')
AND (ciem1.inactive_date IS NULL OR ciem1.active_date <> ciem1.inactive_date) AND ciem2.subscr_no = ciem1.subscr_no
AND ciem2.external_id NOT IN (
'115009','115035','115043','115090','115061','115122','115015','115028','115095','115107','115093','115092','115116','115010','115034','115044','102100','115052','115106','115091','115046',
'115060','115062','115117','115125','115008','115016','115029','115036','102037','115054','115123','115017','115023','115104','115124','115105','115094','115103','115007','115018','115042',
'115045','102506','115102','115053','115114','115115','102131','102231','102232','102016','102034','102035','102047','102086','102071','102201','102245','102260','102240','102285','102295',
'102015','102018','102025','102057','102061','102070','102082','102092','102202','102284','102013','102017','102019','102020','102021','102026','102048','102065','102085','115037','102198',
'102220','102227','102229','102283','102286','102014','102046','102087','102054','102055','102060','102064','102066','102072','102080','102075','102083','115032','102197','102218','102244',
'102293','102050','102053','102073','102076','102093','115025','102200','102261','102239','102294','102022','102023','102049','102045','102078','102219','102246','102228','102259','102230',
'102216','102062','102079','102081','115080','102199','102249','102051','102044','102063','102069','102074','102077','102084','115003','115004','115005','102091','115047','115048','115006',
'115002','115039','115070','115001','102259','102260','102261','102227','102228','102229','102230','102231','102232','102283','102284','102285','102286','102239','102240','102020','102021',
'102022','102023','102018','102019','102025','102026','102042','102043','102056','102058','102116','102233','102234','102236')
AND ciem2.external_id_type = 91 AND ciem2.view_status = 2 AND ciem2.active_date <> ciem2.inactive_date AND ciem2.inactive_date = ciem1.active_date
--AND ss.subscr_no = ciem1.subscr_no AND ss.view_status = 2 AND c.account_no = ss.parent_account_no
--AND ov1.offer_id = ciem1.external_id AND ov1.reseller_version_id = 39 AND ov2.offer_id = ciem2.external_id AND ov2.reseller_version_id = 39
AND NOT EXISTS (SELECT 1 FROM offer_inst_view@cust1 oiv WHERE oiv.subscr_no = ciem2.subscr_no AND oiv.offer_id = 10624 AND oiv.view_status = 2 AND oiv.active_dt > To_Date('23-Feb-2015','dd-mon-yyyy'))
) select distinct
(select distinct first_value(external_id) over (order by active_dt desc, inactive_dt desc nulls first) from customer_id_acct_map@cust1 where (account_no = b.account_no or account_no = b.parent_account_no) and is_current = 1 and external_id_type = 1) account, 
(select distinct first_value(external_id) over (order by active_date desc, inactive_date desc nulls first, external_id_type asc) from customer_id_equip_map_view@cust1 where subscr_no = b.subscr_no and view_status = 2 and external_id_type in (21,22,101,181,191,151,221)) service,
a.bill_period,  a.prev_cutoff_date, a.account_no, b.subscr_no,
(select sv.display_value from subscriber_status@cust1 ss, status_values@cust1 sv where ss.status_id = sv.status_id and ss.subscr_no = b.subscr_no and ss.inactive_dt is null) subscr_status,
b.offer_id, '"'||f.display_value||'"', f.primary_list_price, e.foreign_code, e.offer_type, b.offer_inst_id, b.chg_who, b.chg_dt, b.active_dt, b.inactive_dt,
decode(b.active_dt, b.inactive_dt, 'Cancelled', NULL)Cancelled 
from offer_inst_view@cust1 b, offer_ref@cust1 e, offer_values@cust1 f, reseller_version@cust1 g, cmf@cust1 a
where b.offer_id = e.offer_id and e.offer_id = f.offer_id and e.reseller_version_id = f.reseller_version_id and e.reseller_version_id = g.reseller_version_id
and g.reseller_id = 7 and g.inactive_date is null and g.status in (3) and b.view_status = 2
and ((a.account_no = b.account_no) or (a.account_no = b.parent_account_no))
--PO with missing Discount SO
and f.primary_list_price = 'BP' 
and exists (select 1 from missing_disc where subscr_no = b.subscr_no)
and b.offer_id in (
'115009','115035','115043','115090','115061','115122','115015','115028','115095','115107','115093','115092','115116','115010','115034','115044','102100','115052','115106','115091','115046',
'115060','115062','115117','115125','115008','115016','115029','115036','102037','115054','115123','115017','115023','115104','115124','115105','115094','115103','115007','115018','115042',
'115045','102506','115102','115053','115114','115115','102131','102231','102232','102016','102034','102035','102047','102086','102071','102201','102245','102260','102240','102285','102295',
'102015','102018','102025','102057','102061','102070','102082','102092','102202','102284','102013','102017','102019','102020','102021','102026','102048','102065','102085','115037','102198',
'102220','102227','102229','102283','102286','102014','102046','102087','102054','102055','102060','102064','102066','102072','102080','102075','102083','115032','102197','102218','102244',
'102293','102050','102053','102073','102076','102093','115025','102200','102261','102239','102294','102022','102023','102049','102045','102078','102219','102246','102228','102259','102230',
'102216','102062','102079','102081','115080','102199','102249','102051','102044','102063','102069','102074','102077','102084','115003','115004','115005','102091','115047','115048','115006',
'115002','115039','115070','115001','102259','102260','102261','102227','102228','102229','102230','102231','102232','102283','102284','102285','102286','102239','102240','102020','102021',
'102022','102023','102018','102019','102025','102026','102042','102043','102056','102058','102116','102233','102234','102236'
)
order by a.bill_period, a.account_no, b.subscr_no, e.offer_type, case when to_char(b.offer_id) = foreign_code then 1 else 2 end, b.active_dt,b.inactive_dt;

---Get List of Subscriber with missing Usage discount for VAS - Account Level Case
with lists1 as (select oref.offer_id from offer_ref@cust1 oref, offer_values@cust1 ov, reseller_version@cust1 rv where oref.offer_id = ov.offer_id and oref.offer_type = 1 
                  and ov.primary_list_price = 'VAS' and length(foreign_code) < 10 and rv.reseller_id = 7 and rv.inactive_date is null and rv.status in (3) 
                  and oref.reseller_version_id = rv.reseller_version_id and ov.reseller_version_id = rv.reseller_version_id 
                  and exists (select 1 from offer_ref@cust1 where offer_type = 1 and offer_id = oref.offer_id+200000 and foreign_code = oref.foreign_code)),
ac_usg_disc as (select oiv.account_no from offer_inst_view@cust1 oiv, lists1 l
                  where oiv.view_status = 2 and oiv.inactive_dt is null and oiv.offer_id = l.offer_id
                  and not exists (select 0 from offer_inst_view@cust1 a where a.view_status = 2 and a.offer_id = oiv.offer_id+200000 and a.inactive_dt is null and a.account_no = oiv.account_no)
), 
---Get List of Subscriber with missing Usage discount for VAS - Service Level Case
lists2 as (select oref.offer_id from offer_ref@cust1 oref, offer_values@cust1 ov, reseller_version@cust1 rv  where oref.offer_id = ov.offer_id and oref.offer_type = 3 
              and ov.primary_list_price = 'VAS' and length(foreign_code) < 10 and rv.reseller_id = 7 and rv.inactive_date is null and rv.status in (3) 
              and oref.reseller_version_id = rv.reseller_version_id and ov.reseller_version_id = rv.reseller_version_id 
              and exists (select 1 from offer_ref@cust1 where offer_type = 3 and offer_id = oref.offer_id+200000 and foreign_code = oref.foreign_code)),
svc_usg_disc as (select oiv.parent_account_no, oiv.subscr_no, oiv.subscr_no_resets from offer_inst_view@cust1 oiv, lists2 l
                    where oiv.view_status = 2 and oiv.inactive_dt is null and oiv.offer_id = l.offer_id
                    and not exists (select 0 from offer_inst_view@cust1 a where a.view_status = 2 and a.offer_id = oiv.offer_id+200000 and a.inactive_dt is null and a.subscr_no = oiv.subscr_no) 
                    and exists (select 1 from subscriber_status@cust1 where subscr_no = oiv.subscr_no and subscr_no_resets = oiv.subscr_no_resets and status_id = 1 and inactive_dt is null)
)
select distinct
(select distinct first_value(external_id) over (order by active_dt desc, inactive_dt desc nulls first) from customer_id_acct_map@cust1 where (account_no = b.account_no or account_no = b.parent_account_no) and is_current = 1 and external_id_type = 1) account, 
(select distinct first_value(external_id) over (order by active_date desc, inactive_date desc nulls first, external_id_type asc) from customer_id_equip_map_view@cust1 where subscr_no = b.subscr_no and view_status = 2 and external_id_type in (21,22,101,181,191,151,221)) service,
a.bill_period, a.prev_cutoff_date, a.account_no, b.subscr_no,
(select sv.display_value from subscriber_status@cust1 ss, status_values@cust1 sv where ss.status_id = sv.status_id and ss.subscr_no = b.subscr_no and ss.inactive_dt is null) subscr_status,
b.offer_id, '"'||f.display_value||'"', f.primary_list_price, e.foreign_code, e.offer_type, b.offer_inst_id, b.chg_who, b.chg_dt, b.active_dt, b.inactive_dt,
decode(b.active_dt, b.inactive_dt, 'Cancelled', NULL)Cancelled 
from offer_inst_view@cust1 b, offer_ref@cust1 e, offer_values@cust1 f, reseller_version@cust1 g, cmf@cust1 a
where b.offer_id = e.offer_id and e.offer_id = f.offer_id and e.reseller_version_id = f.reseller_version_id and e.reseller_version_id = g.reseller_version_id
and g.reseller_id = 7 and g.inactive_date is null and g.status in (3) and b.view_status = 2
and ((a.account_no = b.account_no) or (a.account_no = b.parent_account_no))
-- VAS with missing usage discount
and f.primary_list_price = 'VAS' 
and exists (select 1 from (select oref.foreign_code from offer_ref@cust1 oref, offer_values@cust1 ov, reseller_version@cust1 rv where oref.offer_id = ov.offer_id and oref.offer_type = 3 
              and ov.primary_list_price = 'VAS' and length(foreign_code) < 10 and rv.reseller_id = 7 and rv.inactive_date is null and rv.status in (3) 
              and oref.reseller_version_id = rv.reseller_version_id and ov.reseller_version_id = rv.reseller_version_id 
              and exists (select 1 from offer_ref@cust1 where offer_type = 3 and offer_id = oref.offer_id+200000 and foreign_code = oref.foreign_code)) aa 
              where aa.foreign_code = e.foreign_code)                 
and (exists ( select 1 from svc_usg_disc where subscr_no = b.subscr_no and subscr_no = b.subscr_no_resets) or exists (select 1 from ac_usg_disc where account_no = b.parent_account_no))
order by a.bill_period, a.account_no, b.subscr_no, e.offer_type, case when to_char(b.offer_id) = foreign_code then 1 else 2 end, b.active_dt,b.inactive_dt;