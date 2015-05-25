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
select 'ACCOUNT','SERVICE','BP','BILL_PERIOD','ACCOUNT_NO','SUBSCR_NO','SUBSCR_STATUS','OFFER_ID','DISPLAY_VALUE','OFFER_INST_ID','CHG_WHO','CHG_DT','ACTIVE_DT','INACTIVE_DT','CANCELLED' from dual;

select distinct
(select distinct first_value(external_id) over (order by active_date desc, inactive_date desc nulls first) from customer_id_acct_map@cust1 where (account_no = b.account_no or account_no = b.parent_account_no) and is_current = 1 and external_id_type = 1) account, 
(select distinct first_value(external_id) over (order by active_date desc, inactive_date desc nulls first, external_id_type asc) from customer_id_equip_map_view@cust1 where subscr_no = b.subscr_no and view_status = 2 and external_id_type in (21,22,101,181,191,151,221)) service,
a.bill_period, 
a.account_no, b.subscr_no,
(select sv.display_value from subscriber_status@cust1 ss, status_values@cust1 sv where ss.status_id = sv.status_id and ss.subscr_no = b.subscr_no and ss.inactive_dt is null) subscr_status,
b.offer_id, '"'||f.display_value||'"',
b.offer_inst_id, b.chg_who, to_char(b.chg_dt, 'dd-Mon-yyyy hh24:mi:ss') chg_dt, to_char(b.active_dt, 'dd-Mon-yyyy hh24:mi:ss') active_dt, to_char(b.inactive_dt, 'dd-Mon-yyyy hh24:mi:ss') inactive_dt
from offer_inst_view@cust1 b, offer_ref@cust1 e, offer_values@cust1 f, reseller_version@cust1 g, cmf@cust1 a
where b.offer_id = e.offer_id and e.offer_id = f.offer_id
and e.reseller_version_id = f.reseller_version_id
and e.reseller_version_id = g.reseller_version_id
and g.reseller_id = 7 -- M1 reseller
and g.inactive_date is null -- active reseller version
and g.status in (3) -- production should always be 3 PROPAGATED
and b.view_status = 2
and ((a.account_no = b.account_no) or (a.account_no = b.parent_account_no))
and b.offer_id in (3720,3721,3722) -- Global Cap
and (b.inactive_dt != b.active_dt or b.inactive_dt is null) --not cancel
and exists (select oiv.subscr_no from offer_inst_view@cust1 oiv where oiv.subscr_no = b.subscr_no and oiv.view_status = 2 and oiv.offer_id in (3720,3721,3722) and (oiv.active_dt != oiv.inactive_dt or oiv.inactive_dt is null) having count(oiv.offer_inst_id)>1 group by oiv.subscr_no)
order by a.account_no, b.subscr_no, active_dt desc, inactive_dt desc nulls first, b.offer_id, b.offer_inst_id asc
;