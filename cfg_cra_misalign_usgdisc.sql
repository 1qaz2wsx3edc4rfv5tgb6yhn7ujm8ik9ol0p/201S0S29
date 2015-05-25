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

--Scan of misaligned usage discount 
with lists1 as (select offer_id+100000 as offer_id from offer_ref@cust1 oref, reseller_version@cust1 rv  where oref.offer_type = 2 and oref.equip_type_code = 101  and oref.offer_id <> 102147
                          and rv.reseller_id = 7 and rv.inactive_date is null and rv.status in (3) and oref.reseller_version_id = rv.reseller_version_id and length(foreign_code) < 10
                          and exists (select 1 from offer_ref@cust1 where offer_type = 3 and offer_id = oref.offer_id+100000 and foreign_code = oref.foreign_code)),
align_disc as (select oiv.parent_account_no, oiv.subscr_no
                    from offer_inst_view@cust1 oiv, lists1 l
                    where oiv.view_status = 2 and oiv.inactive_dt is null and oiv.offer_id = l.offer_id
                    and exists (select 1 from offer_inst_view@cust1 a where a.view_status = 2 and a.offer_id = oiv.offer_id-100000 and a.inactive_dt is null and a.subscr_no = oiv.subscr_no) 
                    and trunc(oiv.active_dt) > (select nvl(trunc(prev_cutoff_date),add_months(trunc(next_bill_date)-14,-1)) from cmf
                    where account_no = oiv.parent_account_no)
                    and ( 
                                (select trunc(max(inactive_dt)) from offer_inst_view@cust1 a where a.view_status = 2 and a.offer_id = l.offer_id and a.inactive_dt is not null and a.active_dt <> a.inactive_dt and a.subscr_no = oiv.subscr_no) -
                                  trunc(oiv.active_dt) < 0
                                  and
                                  ((select trunc(max(active_dt)) from subscriber_status@cust1 where subscr_no = oiv.subscr_no and status_id = 3 and inactive_dt is not null) <> 
                                  (select trunc(max(inactive_dt)) from offer_inst_view@cust1 a where a.view_status = 2 and a.offer_id = l.offer_id and a.inactive_dt is not null  and a.active_dt <> a.inactive_dt and a.subscr_no = oiv.subscr_no)) 
                                  and 
                                  ((select trunc(max(inactive_dt)) from subscriber_status@cust1 where subscr_no = oiv.subscr_no and status_id = 3 and inactive_dt is not null) <> trunc(oiv.active_dt))
                              )
                    and exists (select 1 from subscriber_status@cust1 where subscr_no = oiv.subscr_no and status_id = 1 and inactive_dt is null) 
                    and not exists (select 0 from offer_inst_view@cust1 a where a.view_status = 2 and a.offer_id = l.offer_id and a.offer_inst_id <> oiv.offer_inst_id and a.inactive_dt is null and a.subscr_no = oiv.subscr_no)
), --Scan of duplicate usage discount
lists2 as (select offer_id+100000 as offer_id from offer_ref@cust1 oref, reseller_version@cust1 rv where oref.offer_type = 2 and oref.equip_type_code = 101  and oref.offer_id <> 102147
                          and rv.reseller_id = 7 and rv.inactive_date is null and rv.status in (3) and oref.reseller_version_id = rv.reseller_version_id and length(foreign_code) < 10
                          and exists (select 1 from offer_ref@cust1 where offer_type = 3 and offer_id = oref.offer_id+100000 and foreign_code = oref.foreign_code)),
dup_disc as (select oiv.parent_account_no, oiv.subscr_no, count(*)
              from offer_inst_view@cust1 oiv, lists2 l
              where oiv.view_status = 2 and oiv.inactive_dt is null and oiv.offer_id = l.offer_id
              and exists (select 1 from offer_inst_view@cust1 a where a.view_status = 2 and a.offer_id = oiv.offer_id-100000 and a.inactive_dt is null and a.subscr_no = oiv.subscr_no) 
              and exists (select 1 from subscriber_status@cust1 where subscr_no = oiv.subscr_no and status_id = 1 and inactive_dt is null) 
              group by oiv.parent_account_no, oiv.subscr_no
              having count(*) > 1
), subscriberlist as ( select distinct subscr_no from (select subscr_no from align_disc union select subscr_no from dup_disc) )
select distinct
(select distinct first_value(external_id) over (order by active_date desc, inactive_date desc nulls first) from customer_id_acct_map@cust1 where (account_no = b.account_no or account_no = b.parent_account_no) and is_current = 1 and external_id_type = 1) account, 
(select distinct first_value(external_id) over (order by active_date desc, inactive_date desc nulls first, external_id_type asc) from customer_id_equip_map_view@cust1 where subscr_no = b.subscr_no and view_status = 2 and external_id_type in (21,22,101,181,191,151,221)) service,
a.bill_period,  a.prev_cutoff_date, a.account_no, b.subscr_no,
(select sv.display_value from subscriber_status@cust1 ss, status_values@cust1 sv where ss.status_id = sv.status_id and ss.subscr_no = b.subscr_no and ss.inactive_dt is null) subscr_status,
b.offer_id, '"'||f.display_value||'"', f.primary_list_price, e.foreign_code, e.offer_type, b.offer_inst_id, b.chg_who, b.chg_dt, b.active_dt, b.inactive_dt,
decode(b.active_dt, b.inactive_dt, 'Cancelled', NULL)Cancelled 
from offer_inst_view@cust1 b, offer_ref@cust1 e, offer_values@cust1 f, reseller_version@cust1 g, cmf@cust1 a
where b.offer_id = e.offer_id and e.offer_id = f.offer_id and e.reseller_version_id = f.reseller_version_id and e.reseller_version_id = g.reseller_version_id
and g.reseller_id = 7 and g.inactive_date is null and g.status in (3) and b.view_status = 2
and ((a.account_no = b.account_no) or (a.account_no = b.parent_account_no))
--PO with misaligned discount usage
and f.primary_list_price = 'BP' and b.offer_id <> e.foreign_code                
and exists (select 1 from subscriberlist where subscr_no = b.subscr_no)
order by a.bill_period, a.account_no, b.subscr_no, e.offer_type, case when to_char(b.offer_id) = foreign_code then 1 else 2 end, b.active_dt,b.inactive_dt;