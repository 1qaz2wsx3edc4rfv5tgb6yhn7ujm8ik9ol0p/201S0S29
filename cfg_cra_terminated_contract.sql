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
select 'OFFER_ID','DISPLAY_VALUE','OFFER_INST_ID','SUBSCR_NO','PARENT_ACCOUNT_NO','ACTIVE_DT','INACTIVE_DT','EXTEND_CONTRACT_DURATION','EXTERNAL_ID','ACTIVE_DATE','BILL_PERIOD' from dual;

SELECT ov.offer_id, '"' || ov.display_value || '"', oiv.offer_inst_id, oiv.subscr_no, oiv.parent_account_no, oiv.active_dt, oiv.inactive_dt,
oiv.EXTEND_CONTRACT_DURATION, ciem.external_id, ciem.active_date, c.bill_period  
FROM offer_values@cust1 ov, offer_inst_view@cust1 oiv, customer_id_equip_map_view@cust1 ciem, cmf@cust1 c, nrc_term_inst@cust1 nti1, nrc_term_ref@cust1 ntr
WHERE ov.PRIMARY_LIST_PRICE IN ('EQUIP','PRCON','SERVC') AND ov.reseller_version_id = (SELECT Max(rv.reseller_version_id) FROM reseller_version@cust1 rv WHERE rv.STATUS=3)  
AND oiv.offer_id = ov.offer_id
AND oiv.inactive_dt >= To_Date('01-Feb-2015','dd-mon-yyyy') AND oiv.inactive_dt <= SYSDATE AND oiv.view_status = 2
AND ciem.subscr_no = oiv.subscr_no AND ciem.external_id_type = 91 AND ciem.view_status = 2 AND ciem.inactive_date IS NULL
AND c.account_no = oiv.parent_account_no and nti1.offer_inst_id = oiv.offer_inst_id AND nti1.RATE_DT >= To_Date('24-Feb-2015','dd-mon-yyyy')
AND ntr.nrc_term_id = nti1.nrc_term_id AND ntr.reseller_version_id = ov.reseller_version_id AND ntr.association_type IN (2,17) 
AND EXISTS (
SELECT 1 FROM nrc_term_inst@cust1 nti 
WHERE nti.offer_inst_id = oiv.offer_inst_id
AND NOT EXISTS (
	SELECT 1 FROM nrc_term_inst@cust1 nti2
	WHERE nti2.offer_inst_id = nti.offer_inst_id
	AND EXISTS (SELECT 1 FROM offer_inst_view@cust1 oiv1 WHERE oiv1.subscr_no = nti.parent_subscr_no AND oiv1.offer_id = 26715 AND oiv1.view_status = 2 AND oiv1.active_dt = nti.apply_date)
	AND EXISTS (SELECT 1 FROM offer_inst_view@cust1 oiv2 WHERE oiv2.subscr_no = nti.parent_subscr_no AND oiv2.offer_id = 26716 AND oiv2.view_status = 2 AND oiv2.active_dt = nti.apply_date)
	AND EXISTS (SELECT 1 FROM offer_inst_view@cust1 oiv3 WHERE oiv3.subscr_no = nti.parent_subscr_no AND oiv3.offer_id = 26738 AND oiv3.view_status = 2 AND oiv3.active_dt = nti.apply_date)
)
) ORDER BY c.bill_period;
