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
select 'ACCOUNT','SERVICE','BILL_PERIOD','PREV_BILL_REFNO','ACCOUNT_NO','SUBSCR_NO','SUBSCR_STATUS','SS_ACTIVE','ACTIVE_COUNT','SUSPEND_COUNT','OFFER_ID','DISPLAY_VALUE','PRIMARY_LIST_PRICE','FOREIGN_CODE','OFFER_TYPE','OFFER_INST_ID','CHG_WHO','CHG_DT','ACTIVE_DT','INACTIVE_DT','CANCELLED','REMARKS' from dual;


select distinct
(select distinct first_value(external_id) over (order by active_date desc, inactive_date desc nulls first) from customer_id_acct_map@cust1 where (account_no = b.account_no or account_no = b.parent_account_no) and is_current = 1 and external_id_type = 1) account, 
(select distinct first_value(external_id) over (order by active_date desc, inactive_date desc nulls first, external_id_type asc) from customer_id_equip_map_view@cust1 where subscr_no = b.subscr_no and view_status = 2 and external_id_type in (21,22,101,181,191,151,221)) service,
a.bill_period, 
a.prev_bill_refno,
a.account_no, b.subscr_no,
(select sv.display_value from subscriber_status@cust1 ss, status_values@cust1 sv where ss.status_id = sv.status_id and ss.subscr_no = b.subscr_no and ss.inactive_dt is null) subscr_status,
(select ss.active_dt from subscriber_status@cust1 ss where ss.subscr_no = b.subscr_no and ss.inactive_dt is null) ss_active,
(select count(1) from subscriber_status@cust1 ss where ss.subscr_no = b.subscr_no and ss.status_id = 1) active_count,
(select count(1) from subscriber_status@cust1 ss where ss.subscr_no = b.subscr_no and ss.status_id = 3) suspend_count,
b.offer_id, '"'||f.display_value||'"', f.primary_list_price, e.foreign_code, 
e.offer_type, b.offer_inst_id, b.chg_who, b.chg_dt, b.active_dt, b.inactive_dt,
decode(b.active_dt, b.inactive_dt, 'Cancelled', NULL)Cancelled, case when trunc(b.chg_dt) = trunc(sysdate) then 'Exclude if has pending Order' end as remarks 
from offer_inst_view@cust1 b, offer_ref@cust1 e, offer_values@cust1 f, reseller_version@cust1 g, cmf@cust1 a
where b.offer_id = e.offer_id and e.offer_id = f.offer_id
and e.reseller_version_id = f.reseller_version_id
and e.reseller_version_id = g.reseller_version_id
and g.reseller_id = 7 -- M1 reseller
and g.inactive_date is null -- active reseller version
and g.status in (3) -- production should always be 3 PROPAGATED
and b.view_status = 2
and ((a.account_no = b.account_no) or (a.account_no = b.parent_account_no))
and exists
(select distinct 1 from (
--This scan is for active parent without bundle 
select oiv.parent_account_no from offer_inst_view@cust1 oiv
where oiv.view_status = 2 and oiv.inactive_dt is null and oiv.offer_id in (115052) 
and not exists (select 1 from offer_inst_view@cust1 a where a.view_status = 2 and a.offer_id in (32539) and a.inactive_dt is null and a.account_no = oiv.parent_account_no)
and exists (select 1 from subscriber_status@cust1 where subscr_no = oiv.subscr_no and status_id = 1 and inactive_dt is null)
UNION all
select oiv.parent_account_no from offer_inst_view@cust1 oiv
where oiv.view_status = 2 and oiv.inactive_dt is null and oiv.offer_id in (115053) 
and not exists (select 1 from offer_inst_view@cust1 a where a.view_status = 2 and a.offer_id in (32540) and a.inactive_dt is null and a.account_no = oiv.parent_account_no)
and exists (select 1 from subscriber_status@cust1 where subscr_no = oiv.subscr_no and status_id = 1 and inactive_dt is null)
UNION all
select oiv.parent_account_no from offer_inst_view@cust1 oiv
where oiv.view_status = 2 and oiv.inactive_dt is null and oiv.offer_id in (115054) 
and not exists (select 1 from offer_inst_view@cust1 a where a.view_status = 2 and a.offer_id in (32541) and a.inactive_dt is null and a.account_no = oiv.parent_account_no)
and exists (select 1 from subscriber_status@cust1 where subscr_no = oiv.subscr_no and status_id = 1 and inactive_dt is null)
UNION all
select oiv.parent_account_no from offer_inst_view@cust1 oiv
where oiv.view_status = 2 and oiv.inactive_dt is null and oiv.offer_id in (115060) 
and not exists (select 1 from offer_inst_view@cust1 a where a.view_status = 2 and a.offer_id in (31249) and a.inactive_dt is null and a.account_no = oiv.parent_account_no)
and exists (select 1 from subscriber_status@cust1 where subscr_no = oiv.subscr_no and status_id = 1 and inactive_dt is null)
UNION all
select oiv.parent_account_no from offer_inst_view@cust1 oiv
where oiv.view_status = 2 and oiv.inactive_dt is null and oiv.offer_id in (115061) 
and not exists (select 1 from offer_inst_view@cust1 a where a.view_status = 2 and a.offer_id in (31250) and a.inactive_dt is null and a.account_no = oiv.parent_account_no)
and exists (select 1 from subscriber_status@cust1 where subscr_no = oiv.subscr_no and status_id = 1 and inactive_dt is null)
UNION all
select oiv.parent_account_no from offer_inst_view@cust1 oiv
where oiv.view_status = 2 and oiv.inactive_dt is null and oiv.offer_id in (115062) 
and not exists (select 1 from offer_inst_view@cust1 a where a.view_status = 2 and a.offer_id in (31251) and a.inactive_dt is null and a.account_no = oiv.parent_account_no)
and exists (select 1 from subscriber_status@cust1 where subscr_no = oiv.subscr_no and status_id = 1 and inactive_dt is null)
UNION all
select oiv.parent_account_no from offer_inst_view@cust1 oiv
where oiv.view_status = 2 and oiv.inactive_dt is null and oiv.offer_id in (115114) 
and not exists (select 1 from offer_inst_view@cust1 a where a.view_status = 2 and a.offer_id in (32570,32578,32586) and a.inactive_dt is null and a.account_no = oiv.parent_account_no)
and exists (select 1 from subscriber_status@cust1 where subscr_no = oiv.subscr_no and status_id = 1 and inactive_dt is null)
UNION all
select oiv.parent_account_no from offer_inst_view@cust1 oiv
where oiv.view_status = 2 and oiv.inactive_dt is null and oiv.offer_id in (115115) 
and not exists (select 1 from offer_inst_view@cust1 a where a.view_status = 2 and a.offer_id in (32571,32579,32587) and a.inactive_dt is null and a.account_no = oiv.parent_account_no)
and exists (select 1 from subscriber_status@cust1 where subscr_no = oiv.subscr_no and status_id = 1 and inactive_dt is null)
UNION all
select oiv.parent_account_no from offer_inst_view@cust1 oiv
where oiv.view_status = 2 and oiv.inactive_dt is null and oiv.offer_id in (115116) 
and not exists (select 1 from offer_inst_view@cust1 a where a.view_status = 2 and a.offer_id in (32572,32580,32588) and a.inactive_dt is null and a.account_no = oiv.parent_account_no)
and exists (select 1 from subscriber_status@cust1 where subscr_no = oiv.subscr_no and status_id = 1 and inactive_dt is null)
UNION all
select oiv.parent_account_no from offer_inst_view@cust1 oiv
where oiv.view_status = 2 and oiv.inactive_dt is null and oiv.offer_id in (115117) 
and not exists (select 1 from offer_inst_view@cust1 a where a.view_status = 2 and a.offer_id in (32573,32581,32589) and a.inactive_dt is null and a.account_no = oiv.parent_account_no)
and exists (select 1 from subscriber_status@cust1 where subscr_no = oiv.subscr_no and status_id = 1 and inactive_dt is null)
UNION all
select oiv.parent_account_no from offer_inst_view@cust1 oiv
where oiv.view_status = 2 and oiv.inactive_dt is null and oiv.offer_id in (115122) 
and not exists (select 1 from offer_inst_view@cust1 a where a.view_status = 2 and a.offer_id in (32574,32582,32590) and a.inactive_dt is null and a.account_no = oiv.parent_account_no)
and exists (select 1 from subscriber_status@cust1 where subscr_no = oiv.subscr_no and status_id = 1 and inactive_dt is null)
UNION all
select oiv.parent_account_no from offer_inst_view@cust1 oiv
where oiv.view_status = 2 and oiv.inactive_dt is null and oiv.offer_id in (115123) 
and not exists (select 1 from offer_inst_view@cust1 a where a.view_status = 2 and a.offer_id in (32575,32583,32591) and a.inactive_dt is null and a.account_no = oiv.parent_account_no)
and exists (select 1 from subscriber_status@cust1 where subscr_no = oiv.subscr_no and status_id = 1 and inactive_dt is null)
UNION all
select oiv.parent_account_no from offer_inst_view@cust1 oiv
where oiv.view_status = 2 and oiv.inactive_dt is null and oiv.offer_id in (115124) 
and not exists (select 1 from offer_inst_view@cust1 a where a.view_status = 2 and a.offer_id in (32576,32584,32592) and a.inactive_dt is null and a.account_no = oiv.parent_account_no)
and exists (select 1 from subscriber_status@cust1 where subscr_no = oiv.subscr_no and status_id = 1 and inactive_dt is null)
UNION all
select oiv.parent_account_no from offer_inst_view@cust1 oiv
where oiv.view_status = 2 and oiv.inactive_dt is null and oiv.offer_id in (115125) 
and not exists (select 1 from offer_inst_view@cust1 a where a.view_status = 2 and a.offer_id in (32577,32585,32593) and a.inactive_dt is null and a.account_no = oiv.parent_account_no)
and exists (select 1 from subscriber_status@cust1 where subscr_no = oiv.subscr_no and status_id = 1 and inactive_dt is null)
UNION all
--   [SCAN DUPLICATE PARENT]  Check if both Parent have Bundle 
select parent_account_no from
(select parent_account_no, count(*) from offer_inst_view@cust1 oiv
where view_status = 2 and inactive_dt is null 
and offer_id in (115052,115053,115054,115060,115061,115062,115114,115115,115116,115117,115122,115123,115124,115125)
and exists  (select 1 from (
            select account_no, count(*) from offer_inst_view@cust1 where view_status = 2 and inactive_dt is null 
            and offer_id in (31249,31250,31251,32539,32540,32541,32570,32571,32572,32573,32574,32575,32576,32577,32578,32579,32580,32581,32582,32583,32584,32585,32586,32587,32588,32589,32590,32591,32592,32593)
            group by account_no having count(*) = 1) aa where aa.account_no = oiv.parent_account_no)
and exists (select 1 from subscriber_status@cust1 where subscr_no = oiv.subscr_no and status_id = 1 and inactive_dt is null)            
group by parent_account_no having count(*) > 1) abc
) where parent_account_no = a.account_no) -- Account to extract for SurfShare
and b.offer_id in (102506,115052,115053,115054,115060,115061,115062,115114,115115,115116,115117,115122,115123,115124,115125,31249,31250,31251,32539,32540,32541,32570,32571,32572,32573,32574,32575,32576,32577,32578,32579,32580,32581,32582,32583,32584,32585,32586,32587,32588,32589,32590,32591,32592,32593) -- SurfShare
order by a.bill_period, a.account_no, b.subscr_no, f.primary_list_price, e.offer_type,  b.active_dt,e.foreign_code, b.offer_id asc;
