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
select 'ACCOUNT','BILL_PERIOD','PREV_BILL_REFNO','ACCOUNT_NO','ACCOUNT_TYPE','ACCOUNT_CATEGORY','STATUS','ACCOUNT_STATUS_DT','DATE_ACTIVE','DATE_INACTIVE','DATE_CREATED','CHG_DATE','CHG_WHO' from dual;

select distinct
(select distinct first_value(external_id) over (order by active_date desc, inactive_date desc nulls first) from customer_id_acct_map@cust1 where account_no = a.account_no and is_current = 1 and external_id_type = 1) account2, 
a.bill_period, a.prev_bill_refno, a.account_no, a.account_type, a.account_category,
decode (a.account_status, -3, 'PENDING', -2, 'DISC_DONE', -1, 'NEW', 0, 'CURRENT', 1, 'DISC_REQ') STATUS, 
a.account_status_dt, a.date_active, a.date_inactive, a.date_created, a.chg_date, a.chg_who
from cmf a
where not exists (select 1 from offer_inst_view oiv where oiv.view_status = 2 and oiv.offer_id = 51004365 and oiv.inactive_dt is null and a.account_no = oiv.account_no )
and a.date_inactive is null
order by a.account_no
;
