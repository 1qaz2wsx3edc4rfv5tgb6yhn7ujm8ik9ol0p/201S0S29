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
select 'ACCOUNT','SERVICE','BILL_PERIOD','PREV_CUTOFF_DATE','ACCOUNT_NO','SUBSCR_NO','SUBSCR_STATUS','OFFER_ID','DISPLAY_VALUE','PRIMARY_LIST_PRICE','FOREIGN_CODE','OFFER_TYPE','OFFER_INST_ID','CHG_WHO','CHG_DT','ACTIVE_DT','INACTIVE_DT','CANCELLED','REMARKS' from dual;


select distinct
(select distinct external_id from customer_id_acct_map where (account_no = b.account_no or account_no = b.parent_account_no)  /*and inactive_date is null*/ and is_current = 1 and external_id_type = 1) ext_account, 
(select distinct external_id from customer_id_equip_map_view where subscr_no = b.subscr_no and is_current = 1 and view_status = 2 /* and inactive_dt is null */and external_id_type in (21,22,181,191,151,221)) service, 
a.bill_period,  a.prev_cutoff_date, a.account_no, b.subscr_no,
(select sv.display_value from subscriber_status ss, status_values sv where ss.status_id = sv.status_id and ss.subscr_no = b.subscr_no and ss.inactive_dt is null) subscr_status,
b.offer_id, f.display_value, f.primary_list_price, e.foreign_code, e.offer_type, b.offer_inst_id, b.chg_who, b.chg_dt, b.active_dt, b.inactive_dt,
decode(b.active_dt, b.inactive_dt, 'Cancelled', null) cancelled, case when trunc(b.chg_dt) = trunc(sysdate) then 'Exclude if has pending Order' end as remarks
from offer_inst_view b, offer_ref e, offer_values f, reseller_version g, cmf a
where b.offer_id = e.offer_id and e.offer_id = f.offer_id and e.reseller_version_id = f.reseller_version_id and e.reseller_version_id = g.reseller_version_id
and g.reseller_id = 7 and g.inactive_date is null and g.status in (3) and b.view_status = 2 and ((a.account_no = b.account_no) or (a.account_no = b.parent_account_no))
and f.primary_list_price = 'BP' and b.offer_id <> e.foreign_code+200000 --RC SO Only
and b.subscr_no in 
(
select subscr_no from 
    (
      with lists as (select offer_id from offer_ref oref, reseller_version rv  where oref.offer_type = 2 --and oref.equip_type_code = 101 
                            and rv.reseller_id = 7 and rv.inactive_date is null and rv.status in (3) and oref.reseller_version_id = rv.reseller_version_id and length(foreign_code) < 10
                            and exists (select 1 from offer_ref where offer_type = 3 and offer_id = oref.offer_id-100000 and foreign_code = oref.foreign_code))
      select oiv.subscr_no
      from offer_inst_view oiv, lists l
      where oiv.view_status = 2 and oiv.inactive_dt is null and oiv.offer_id = l.offer_id
      and not exists (select 1 from offer_inst_view a where a.view_status = 2 and a.offer_id = oiv.offer_id-100000 and a.inactive_dt is null and a.subscr_no = oiv.subscr_no) 
      and exists (select 1 from subscriber_status where subscr_no = oiv.subscr_no and status_id = 1 and inactive_dt is null) 
    )
) 
order by a.bill_period, a.account_no, b.subscr_no, e.offer_type, case when to_char(b.offer_id) = foreign_code then 1 else 2 end, b.active_dt,b.inactive_dt;


select distinct
accountlist.remarks as scan_type,
(select distinct external_id from customer_id_acct_map where (account_no = b.account_no or account_no = b.parent_account_no)  /*and inactive_date is null*/ and is_current = 1 and external_id_type = 1) ext_account, 
(select distinct external_id from customer_id_equip_map_view where subscr_no = b.subscr_no and is_current = 1 and view_status = 2 /* and inactive_dt is null */and external_id_type in (21,22,181,191,151,221)) service, 
a.bill_period,  a.prev_cutoff_date, a.account_no, b.subscr_no,
(select sv.display_value from subscriber_status ss, status_values sv where ss.status_id = sv.status_id and ss.subscr_no = b.subscr_no and ss.inactive_dt is null) subscr_status,
b.offer_id, f.display_value, f.primary_list_price, e.foreign_code, e.offer_type, b.offer_inst_id, b.chg_who, b.chg_dt, b.active_dt, b.inactive_dt,
decode(b.active_dt, b.inactive_dt, 'Cancelled', null)cancelled,case when trunc(b.chg_dt) = trunc(sysdate) then 'Exclude if has pending Order' end as remarks 
from  offer_inst_view b, 
            offer_ref e, 
            offer_values f, 
            reseller_version g, 
            cmf a, 
            (select account_no, remarks from 
              (select account_no, 'VAS with Missing Discount SO' as remarks from
                (---Get List of Subscriber with missing Usage discount for VAS - Account Level Case
                with lists as (select oref.offer_id from offer_ref oref, offer_values ov, reseller_version rv  where oref.offer_id = ov.offer_id and oref.offer_type = 1 
                                          and ov.primary_list_price = 'VAS' and length(foreign_code) < 10 and rv.reseller_id = 7 and rv.inactive_date is null and rv.status in (3) 
                                          and oref.reseller_version_id = rv.reseller_version_id and ov.reseller_version_id = rv.reseller_version_id 
                                          and exists (select 1 from offer_ref where offer_type = 1 and offer_id = oref.offer_id+200000 and foreign_code = oref.foreign_code))
                select oiv.account_no from offer_inst_view oiv, lists l
                where oiv.view_status = 2 and oiv.inactive_dt is null and oiv.offer_id = l.offer_id
                and not exists (select 0 from offer_inst_view a where a.view_status = 2 and a.offer_id = oiv.offer_id+200000 and a.inactive_dt is null and a.account_no = oiv.account_no) )
                union
                select account_no, 'VAS with Multiple Discount SO' as remarks from
                ( ---Get List of Subscriber with missing Usage discount for VAS - Account Level Case
                with lists as (select oref.offer_id from offer_ref oref, offer_values ov, reseller_version rv  where oref.offer_id = ov.offer_id and oref.offer_type = 1 
                                          and ov.primary_list_price = 'VAS' and length(foreign_code) < 10 and rv.reseller_id = 7 and rv.inactive_date is null and rv.status in (3) 
                                          and oref.reseller_version_id = rv.reseller_version_id and ov.reseller_version_id = rv.reseller_version_id 
                                          and exists (select 1 from offer_ref where offer_type = 1 and offer_id = oref.offer_id+200000 and foreign_code = oref.foreign_code))
                select oiv.account_no, count(*) from offer_inst_view oiv, lists l
                where oiv.view_status = 2 and oiv.inactive_dt is null and oiv.offer_id = l.offer_id
                and not exists (select 0 from offer_inst_view a where a.view_status = 2 and a.offer_id = oiv.offer_id+200000 and a.inactive_dt is null and a.account_no = oiv.account_no) 
                group by oiv.account_no having count(*) > 1 )
              )) accountlist 
where b.offer_id = e.offer_id and e.offer_id = f.offer_id and e.reseller_version_id = f.reseller_version_id and e.reseller_version_id = g.reseller_version_id
and g.reseller_id = 7 and g.inactive_date is null and g.status in (3) and b.view_status = 2
and ((a.account_no = b.account_no) or (a.account_no = b.parent_account_no))
-- VAS with missing usage discount
and f.primary_list_price = 'VAS' 
and exists (select 1 from (select oref.foreign_code from offer_ref oref, offer_values ov, reseller_version rv  where oref.offer_id = ov.offer_id and oref.offer_type = 1 
                          and ov.primary_list_price = 'VAS' and length(foreign_code) < 10 and rv.reseller_id = 7 and rv.inactive_date is null and rv.status in (3) 
                          and oref.reseller_version_id = rv.reseller_version_id and ov.reseller_version_id = rv.reseller_version_id 
                          and exists (select 1 from offer_ref where offer_type = 1 and offer_id = oref.offer_id+200000 and foreign_code = oref.foreign_code)) aa 
                        where aa.foreign_code = e.foreign_code)                 
and a.account_no = accountlist.account_no
union
select distinct
svslist.remarks as scan_type,
(select distinct external_id from customer_id_acct_map where (account_no = b.account_no or account_no = b.parent_account_no)  /*and inactive_date is null*/ and is_current = 1 and external_id_type = 1) ext_account, 
(select distinct external_id from customer_id_equip_map_view where subscr_no = b.subscr_no and is_current = 1 and view_status = 2 /* and inactive_dt is null */and external_id_type in (21,22,181,191,151,221)) service, 
a.bill_period,  a.prev_cutoff_date, a.account_no, b.subscr_no,
(select sv.display_value from subscriber_status ss, status_values sv where ss.status_id = sv.status_id and ss.subscr_no = b.subscr_no and ss.inactive_dt is null) subscr_status,
b.offer_id, f.display_value, f.primary_list_price, e.foreign_code, e.offer_type, b.offer_inst_id, b.chg_who, b.chg_dt, b.active_dt, b.inactive_dt,
decode(b.active_dt, b.inactive_dt, 'Cancelled', null)cancelled,case when trunc(b.chg_dt) = trunc(sysdate) then 'Exclude if has pending Order' end as remarks 
from    offer_inst_view b, 
              offer_ref e, 
              offer_values f, 
              reseller_version g, cmf a,
              (select distinct subscr_no, remarks from (
              select subscr_no, 'VAS with Missing Discount SO' as remarks from
              (---Get List of Subscriber with missing Usage discount for VAS - Service Level Case
               with lists as (select oref.offer_id from offer_ref oref, offer_values ov, reseller_version rv  where oref.offer_id = ov.offer_id and oref.offer_type = 3 
                                        and ov.primary_list_price = 'VAS' and length(foreign_code) < 10 and rv.reseller_id = 7 and rv.inactive_date is null and rv.status in (3) 
                                        and oref.reseller_version_id = rv.reseller_version_id and ov.reseller_version_id = rv.reseller_version_id 
                                        and exists (select 1 from offer_ref where offer_type = 3 and offer_id = oref.offer_id+200000 and foreign_code = oref.foreign_code))
              select oiv.parent_account_no, oiv.subscr_no  from offer_inst_view oiv, lists l
              where oiv.view_status = 2 and oiv.inactive_dt is null and oiv.offer_id = l.offer_id
              and not exists (select 0 from offer_inst_view a where a.view_status = 2 and a.offer_id = oiv.offer_id+200000 and a.inactive_dt is null and a.subscr_no = oiv.subscr_no) 
              and exists (select 1 from subscriber_status where subscr_no = oiv.subscr_no and status_id = 1 and inactive_dt is null) 
              )
              union
              select subscr_no, 'VAS with Multiple Discount SO' as remarks from
              (---Get List of Subscriber with Duplicate Usage discount for VAS - Service Level Case
              with lists as (select oref.offer_id from offer_ref oref, offer_values ov, reseller_version rv  where oref.offer_id = ov.offer_id and oref.offer_type = 3 
                                        and ov.primary_list_price = 'VAS' and length(foreign_code) < 10 and rv.reseller_id = 7 and rv.inactive_date is null and rv.status in (3) 
                                        and oref.reseller_version_id = rv.reseller_version_id and ov.reseller_version_id = rv.reseller_version_id 
                                        and exists (select 1 from offer_ref where offer_type = 3 and offer_id = oref.offer_id+200000 and foreign_code = oref.foreign_code))
              select oiv.parent_account_no, oiv.subscr_no, count(*)  from offer_inst_view oiv, lists l
              where oiv.view_status = 2 and oiv.inactive_dt is null and oiv.offer_id = l.offer_id
              and not exists (select 0 from offer_inst_view a where a.view_status = 2 and a.offer_id = oiv.offer_id+200000 and a.inactive_dt is null and a.subscr_no = oiv.subscr_no) 
              and exists (select 1 from subscriber_status where subscr_no = oiv.subscr_no and status_id = 1 and inactive_dt is null) 
              group by oiv.parent_account_no, oiv.subscr_no having count(*) > 1
              ))) svslist
where b.offer_id = e.offer_id and e.offer_id = f.offer_id and e.reseller_version_id = f.reseller_version_id and e.reseller_version_id = g.reseller_version_id
and g.reseller_id = 7 and g.inactive_date is null and g.status in (3) and b.view_status = 2
and ((a.account_no = b.account_no) or (a.account_no = b.parent_account_no))
and f.primary_list_price = 'VAS' 
and exists (select 1 from (select oref.foreign_code from offer_ref oref, offer_values ov, reseller_version rv  where oref.offer_id = ov.offer_id and oref.offer_type = 3 
                          and ov.primary_list_price = 'VAS' and length(foreign_code) < 10 and rv.reseller_id = 7 and rv.inactive_date is null and rv.status in (3) 
                          and oref.reseller_version_id = rv.reseller_version_id and ov.reseller_version_id = rv.reseller_version_id 
                          and exists (select 1 from offer_ref where offer_type = 3 and offer_id = oref.offer_id+200000 and foreign_code = oref.foreign_code)) aa 
                        where aa.foreign_code = e.foreign_code)                 
and b.subscr_no =  svslist.subscr_no
order by 1, 4, 2, 3, 9, 17, 18;