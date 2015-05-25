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
select 'ACCOUNT','SERVICE','BILL_PERIOD','PREV_BILL_REFNO','ACCOUNT_NO','SUBSCR_NO','SUBSCR_STATUS','SS_ACTIVE','ACTIVE_COUNT','SUSPEND_COUNT','OFFER_ID','DISPLAY_VALUE','PRIMARY_LIST_PRICE','FOREIGN_CODE','OFFER_TYPE','OFFER_INST_ID','CHG_WHO','CHG_DT','ACTIVE_DT','INACTIVE_DT','CANCELLED' from dual;

select distinct
/* (
select count(*) from t_service@crm2p where product_component_ref_id = '19549' 
and status_cd = 1 and (billing_end_dt is null or billing_end_dt > sysdate)
and exists (
	select 1 from (
		select 
		(select distinct first_value(external_id) over (order by active_dt desc, inactive_dt desc nulls first) from customer_id_acct_map@cust1 where (account_no = b.account_no or account_no = b.parent_account_no) and is_current = 1 and external_id_type = 1) account, 
		(select distinct first_value(external_id) over (order by active_date desc, inactive_date desc nulls first, external_id_type asc) from customer_id_equip_map_view@cust1 where subscr_no = b.subscr_no and is_current = 1 and view_status = 2 and external_id_type in (21,22,101,181,191,151,221)) service
		from offer_inst_view@cust1 b
	) where customer_account_id = account and service_id = service)
) NO_GPRS, */
(select distinct first_value(external_id) over (order by active_date desc, inactive_date desc nulls first) from customer_id_acct_map@cust1 where (account_no = b.account_no or account_no = b.parent_account_no) and is_current = 1 and external_id_type = 1) account, 
(select distinct first_value(external_id) over (order by active_date desc, inactive_date desc nulls first, external_id_type asc) from customer_id_equip_map_view@cust1 where subscr_no = b.subscr_no and view_status = 2 and external_id_type in (21,22,101,181,191,151,221)) service,
a.bill_period, 
a.prev_bill_refno,
a.account_no, b.subscr_no,
(select sv.display_value from subscriber_status@cust1 ss, status_values@cust1 sv where ss.status_id = sv.status_id and ss.subscr_no = b.subscr_no and ss.inactive_dt is null) subscr_status,
(select ss.active_dt from subscriber_status@cust1 ss where ss.subscr_no = b.subscr_no and ss.inactive_dt is null) ss_active,
(select count(1) from subscriber_status@cust1 ss where ss.subscr_no = b.subscr_no and ss.status_id = 1) active_count,
(select count(1) from subscriber_status@cust1 ss where ss.subscr_no = b.subscr_no and ss.status_id = 3) suspend_count,
b.offer_id, f.display_value, f.primary_list_price, e.foreign_code, 
e.offer_type, b.offer_inst_id, b.chg_who, b.chg_dt, b.active_dt, b.inactive_dt,
decode(b.active_dt, b.inactive_dt, 'Cancelled', NULL)Cancelled--, 
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
(
	select 1 from (
	select distinct po.subscr_no from subscriberlist po
	where 1=1
	and po.offer_type = 'po'
	and po.datagrp = 'surfshare' --in ('gsm data','mdata')
	and exists ( -- invalid cases
	  select 1 from subscriberlist so
	  where 1=1 
	  and so.offer_type = 'so'
	  and po.account_no = so.parent_account_no
	  and po.bundletype = so.bundletype
	  and (
		(so.start_dt > po.start_dt) or
		(so.end_dt < po.end_dt) or (so.end_dt is null and po.end_dt is not null)
	  )
	) and not exists ( -- no existing valid cases
	  select 1 from subscriberlist so
	  where 1=1 
	  and so.offer_type = 'so'
	  and so.parent_account_no = po.account_no
	  and po.bundletype = so.bundletype
	  and (
		((so.start_dt < po.start_dt) or (sysdate-so.start_dt > 120)) and
		((so.end_dt > po.end_dt) or (so.end_dt is null and po.end_dt is not null))
	  )
	)
	) where subscr_no = b.subscr_no
)
and b.offer_id in (
	3134,3138,3154,3157,3155,3158,3135,3139,3968,3968,3161,3178 -- orig data plan discount (1 to 1 mapping))
	,30369,30370,30397,30398 -- old gsm discount offer
	,30397,30398 -- new gsm discount offer
	,3186,3187,3198,3199 -- mdata discount offer
	,32539,32540,32541,31249,31250,31251,32570,32571,32572,32573,32574,32575,32576,32577 -- surfshare first plan (1 to 1 mapping)
	,32578,32579,32580,32581,32582,32583,32584,32585 -- surfshare tier 2
	,32586,32587,32588,32589,32590,32591,32592,32593 -- surfshare tier 3
	,102044,102060,102061,102045,102073,102074,102066,102078      -- original data plan
	,102037,102100,115007,115008,115009,115010,115015,115016,115017,115018,115023,115028,115029,115034,115035,115036,115042,115043 -- old gsm
	,115090,115091,115092,115093,115094,115095,115102,115103,115104,115105,115106,115107 -- new gsm
	,102091,115001,115002,115003,115004,115005,115006,115039,115047,115048,115070 -- mdata
	,102506,115052,115053,115054,115060,115061,115062,115114,115115,115116,115117,115122,115123,115124,115125 -- surfshare      
	,4038,7971
) -- data offers related
order by a.account_no, b.subscr_no, f.primary_list_price, e.offer_type,  b.active_dt,e.foreign_code, b.offer_id asc;