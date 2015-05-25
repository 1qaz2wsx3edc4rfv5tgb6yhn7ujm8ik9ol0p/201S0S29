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
select 'OFFER_ID', 'DISPLAY_VALUE', 'OFFER_INST_ID', 'SUBSCR_NO', 'PARENT_ACCOUNT_NO', 'OFFER_ID', 'ACTIVE_DT', 'BILL_PERIOD', 'NEXT_BILL_DATE' from dual;

SELECT ov.offer_id, '"'||ov.display_value||'"', oiv.offer_inst_id, oiv.subscr_no, oiv.parent_account_no, oiv2.offer_id, oiv2.active_dt, c.bill_period , c.next_bill_date
FROM offer_values@cust1 ov, offer_inst_view@cust1 oiv, offer_inst_view@cust1 oiv2, subscriber_status@cust1 ss, cmf@cust1 c
WHERE (ov.OFFER_ID BETWEEN 200000 AND 299999 AND ov.reseller_version_id = 39) AND ov.PRIMARY_LIST_PRICE = 'BP'
AND oiv.offer_id = ov.offer_id AND oiv.view_status = 2 AND oiv.inactive_dt IS NULL
AND oiv2.subscr_no = oiv.subscr_no AND (oiv2.offer_id BETWEEN 100000 AND 199999) AND oiv2.view_status = 2 AND oiv2.inactive_dt IS null
AND ss.subscr_no = oiv.subscr_no AND ss.inactive_dt IS NULL AND ss.status_id = 1 AND NOT EXISTS
(SELECT 1 FROM offer_inst_view@cust1 oiv2 WHERE oiv2.subscr_no = oiv.subscr_no AND oiv2.offer_id = (ov.offer_id-100000) AND oiv2.view_status = 2 and oiv2.inactive_dt IS null)
AND c.account_no = oiv.parent_account_no;
