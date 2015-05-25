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
select 'ACCOUNT','SERVICE','BILL_PERIOD','PREV_CUTOFF_DATE','ACCOUNT_NO','SUBSCR_NO','SUBSCR_STATUS','OFFER_ID','DISPLAY_VALUE','PRIMARY_LIST_PRICE','FOREIGN_CODE','OFFER_TYPE','OFFER_INST_ID','CHG_WHO','CHG_DT','ACTIVE_DT','INACTIVE_DT','CANCELLED','REMARK' from dual;

create table temp_subscriber as 
with to_check_cbp as (
  SELECT subscr_no FROM customer_id_equip_map_view@cust1 ciem
  WHERE 1=1
  AND ciem.external_id_type = 91
  GROUP BY ciem.subscr_no
  HAVING Count(DISTINCT external_id) > 1
), data_bundle_po as (
    SELECT subscr_no FROM offer_inst_view@cust1 z
    WHERE 1=1
    AND z.offer_id IN (
      102121,102122,102104,102114,102108,102109,102151,102012,102183,102185,
      102152,102153,102154,102155,102156,102172,102173,102175,102184,102157,
      102158,102159,102160,102161,102178,102180,102010,102298,102040,102253,
      102008,102296,102009,102297,102007,102186,102187,102188,102189,102190,
      102208,102209,102212,102225,102215,102191,102192,102193,102194,102195,
      102210,102213,102214,102224,102211,102266,102267,102268,102278,102272,
      102273,102274,102280,102275,102276,102277,102281,102291,102292,102269,
      102270,102271,102279,102223,102207,102196,102162,102163,102164,102165,
      102166,102177,102179,102181,102203,102167,102168,102169,102170,102171,
      102174,102182,102126,102011,102130,102041,102257,102258,102033,102141,
      102142,102143,102144,102251,102106,102113,102024,102103,102107,102134,
      102105,102123,102110,102101,102127,102128,102129,102131,119154,102002,
      102006,102038,102039,102004,102299,102005,102300,102289,102135,102241,
      102242,102248,102136,102243,102262,102264,102265,102287,102288,102263,
      102252,102206,102119,102137,102282,102256,102254,102255,102124,102102,
      102120,102118,102115,102030,102031,102028,102029,102506,115052,115053,
      115054,115060,115061,115062,115114,115115,115116,115117,115122,115123,115124,115125)
    AND z.view_status = 2
	  AND (z.inactive_dt <> z.active_dt or z.inactive_dt is null)
), missing_so as (
  SELECT subscr_no FROM offer_inst_view@cust1 x
  WHERE x.view_status = 2
  AND x.offer_id IN (30398)
  AND (x.active_dt <> x.inactive_dt or x.inactive_dt is null)
  AND NOT EXISTS (
    SELECT 1 FROM offer_inst_view@cust1 y, offer_ref@cust1 orf, reseller_version@cust1 rv
    WHERE y.view_status = 2
    AND rv.status = 3 and rv.inactive_date is null 
    and rv.reseller_id = 7
    and rv.reseller_version_id = orf.reseller_version_id
    AND x.subscr_no = y.subscr_no
    AND y.offer_id = orf.offer_id
    AND x.offer_id <> y.offer_id
    AND orf.offer_type = 3
    AND y.offer_id IN (
      3140,3136,9977,32576,32580,32583,32584,32588,3135,3157,3169,30369,32540,
      32541,3154,3177,3187,31249,32570,32581,32582,3155,3168,3199,30370,32575,
      32585,32586,32589,32590,32591,3186,3138,3968,26497,30397,31251,32539,32571,
      32573,32577,3129,3137,3139,3195,31250,32579,32592,32593,3134,3158,3161,3170,
      3178,3198,9979,32572,32574,32578,32587)
    AND y.active_dt <> x.active_dt
	  AND (y.active_dt <> y.inactive_dt or y.inactive_dt is null)
  )
  AND NOT EXISTS ( select 1 from data_bundle_po z where x.subscr_no = z.subscr_no )
)
----1. Backdated Late PO (1st query to get all subscribers)
select /*+ LEADING(to_check_cbp) */ distinct 
oiv.parent_account_no, oiv.subscr_no, a.bill_period 
from offer_inst_view@cust1 oiv, offer_ref@cust1 oref, reseller_version@cust1 rv, cmf@cust1 a
where oiv.offer_id = oref.offer_id
AND oiv.parent_account_no = a.account_no
--AND a.bill_period IN ('M07','C07')  /*To target BC*/
and oref.offer_type = 2
and oref.equip_type_code = 101
and oref.reseller_version_id = rv.reseller_version_id
and rv.reseller_id = 7 -- M1 reseller
and rv.inactive_date is null -- active reseller version
and rv.status in (3) -- production should always be 3 PROPAGATED
and oiv.view_status = 2 and oiv.chg_who = 'prod4acn' -- Provision by Web+/OSM 
and oiv.inactive_dt is null -- Active
and oiv.chg_dt > oiv.active_dt + 16.5/24
AND oiv.chg_dt >= To_Date('20150429','yyyymmdd')
--AND oiv.chg_dt < To_Date('20150505','yyyymmdd')
--AND oiv.subscr_no IN ()
---------To check CBP
AND EXISTS ( select 1 from to_check_cbp where subscr_no = oiv.subscr_no )
---------To check CDR exists between Late PO period
AND EXISTS (
  select 1
  from cdr_unbilled@cust1 b, cdr_data@cust1 a -- tarrif_plan_offer_id
  where a.msg_id = b.msg_id AND a.msg_id2 = b.msg_id2
  and a.split_row_num = b.split_row_num
  and a.initial_aut_id in (1284,1286,1287,1293,1295,1297,1298,1300,1302,1303,1304,1305,1307)
  AND a.trans_dt >= oiv.active_dt
  AND a.trans_dt < Trunc(oiv.chg_dt + 1)
  AND b.subscr_no = oiv.subscr_no
)
---------To exclude CBP from old to new BP (new BP can still be discounted under old BP)
AND NOT EXISTS (
  SELECT 1 FROM offer_inst_view@cust1 g
  WHERE g.view_status = 2
  AND g.subscr_no = oiv.subscr_no
  AND g.offer_id IN (30370,30397)
  AND (g.active_dt <> g.inactive_dt or g.inactive_dt is null)
  AND EXISTS (
    SELECT 1 FROM offer_inst_view@cust1 h
    WHERE h.view_status = 2
    AND h.subscr_no = g.subscr_no
    AND h.offer_id IN (30398)
    AND h.active_dt > g.active_dt
	AND (h.active_dt <> h.inactive_dt or h.inactive_dt is null)
  )
)
AND NOT EXISTS (
  SELECT 1 FROM offer_inst_view@cust1 g
  WHERE g.view_status = 2
  AND g.subscr_no = oiv.subscr_no
  AND g.offer_id IN (30398)
  AND (g.active_dt <> g.inactive_dt or g.inactive_dt is null)
  AND EXISTS (
    SELECT 1 FROM offer_inst_view@cust1 h
    WHERE h.view_status = 2
    AND h.subscr_no = g.subscr_no
    AND h.offer_id IN (30397)
    AND h.active_dt > g.active_dt
	AND (h.active_dt <> h.inactive_dt or h.inactive_dt is null)
  )
)
AND NOT EXISTS (
  SELECT 1 FROM offer_inst_view@cust1 g
  WHERE g.view_status = 2
  AND g.subscr_no = oiv.subscr_no
  AND (g.active_dt <> g.inactive_dt or g.inactive_dt is null)
  AND g.offer_id IN (3198,3186,3199,3187)
  AND EXISTS (
    SELECT 1 FROM offer_inst_view@cust1 h
    WHERE h.view_status = 2
    AND h.subscr_no = g.subscr_no
    AND h.offer_id IN (3198,3186,3199,3187)
    AND h.active_dt > g.active_dt
	AND (h.active_dt <> h.inactive_dt or h.inactive_dt is null)
  )
)
AND NOT EXISTS (
  SELECT 1 FROM offer_inst_view@cust1 g
  WHERE g.view_status = 2
  AND g.subscr_no = oiv.subscr_no
  AND g.offer_id IN (30369)
  AND (g.active_dt <> g.inactive_dt or g.inactive_dt is null)
  AND EXISTS (
    SELECT 1 FROM offer_inst_view@cust1 h
    WHERE h.view_status = 2
    AND h.subscr_no = g.subscr_no
    AND h.offer_id IN (30397,30398)
    AND h.active_dt > g.active_dt
  	AND (h.active_dt <> h.inactive_dt or h.inactive_dt is null)
  )
)
AND NOT EXISTS ( select 1 from missing_so x where x.subscr_no = oiv.subscr_no );


--2. Pull out all to get all with 1day GPRS
-- Offer Inst
select distinct
(select distinct first_value(external_id) over (order by active_date desc, inactive_date desc nulls first) from customer_id_acct_map@cust1 where (account_no = b.account_no or account_no = b.parent_account_no) and is_current = 1 and external_id_type = 1) account, 
(select distinct first_value(external_id) over (order by active_date desc, inactive_date desc nulls first, external_id_type asc) from customer_id_equip_map_view@cust1 where subscr_no = b.subscr_no and view_status = 2 and external_id_type in (21,22,101,181,191,151,221)) service,
--a.bill_name_pre, a.bill_fname, a.bill_lname,
a.bill_period, a.prev_bill_refno, a.account_no, b.subscr_no,
(select sv.display_value from subscriber_status@cust1 ss, status_values@cust1 sv where ss.status_id = sv.status_id and ss.subscr_no = b.subscr_no and ss.inactive_dt is null) subscr_status,
b.offer_id, '"'||f.display_value||'"', f.primary_list_price, e.foreign_code, e.offer_type, b.offer_inst_id, b.chg_who, b.chg_dt, b.active_dt, b.inactive_dt,
decode(b.active_dt, b.inactive_dt, 'Cancelled', NULL) Cancelled,
'Require ACTION' REMARK
from offer_inst_view@cust1 b, offer_ref@cust1 e, offer_values@cust1 f, reseller_version@cust1 g, cmf@cust1 a
where b.offer_id = e.offer_id and e.offer_id = f.offer_id
and e.reseller_version_id = f.reseller_version_id
and e.reseller_version_id = g.reseller_version_id
and g.reseller_id = 7 -- M1 reseller
and g.status in (3) -- production should always be 3 PROPAGATED
and b.view_status = 2
and ((a.account_no = b.account_no) or (a.account_no = b.parent_account_no))
and exists ( select 1 from temp_subscriber where subscr_no = b.subscr_no )
and (e.offer_type = 2 or b.offer_id in (
	3140,3137,3136,3168,3169,3170,3177,3178,3195,3134,3138,3154,3155,3158,3161,3134,3138,3154,3155,3158,3161,3168,3169,3170,3177,3178,3195,3129,3135,3139,3157,3154,3158,3170,3178,3129,3135,3139,3157,3134,3138,3154,3155,3158,3161,3129,3135,3139,3157,3168,3169,3170,3177,3178,3195,3134,3138,3154,3155,3158,3161,3154,3158,3155,3129,3135,3139,3157,3134,3161,3138,3168,3169,3170,3177,3178,3195,3134,3138,3154,3155,3158,3161,3129,3135,3139,3157,3129,3134,3135,3138,3139,3155,3157,3161,3168,3169,3177,3195,3168,3169,3170,3177,3178,3195,3168,3169,3170,3177,3178,3195,3129,3135,3139,3157,3129,3135,3139,3157,3134,3138,3154,3155,3158,3161,3129,3135,3139,3157,3168,3169,3170,3177,3178,3195,3134,3138,3154,3155,3158,3161,3177,3178,3195,3134,3138,3154,3155,3158,3161,3168,3169,3170,3177,3178,3195,3129,3135,3139,3157,3168,3169,3170,3134,3138,3154,3155,3158,3161,3129,3135,3139,3157,3168,3169,3170,3177,3178,3195,3129,3135,3139,3157,3154,3155,3158,3161,3134,3138,3177,3178,3195,3168,3169,3170,3134,3135,3154,3155,3157,3158,3968,26497,3129,3195,9977,9979,
	3134,3135,3154,3155,3157,3158,3968,26497,3129,3195,9977,9979,3968,3154,10624,26497,7971,3135,3155,4038,3720,3721,3722,30369,30370,30397,30398,3198,3186,3199,3187,31249,31250,31251,32539,32540,32541,32570,32571,32572,32573,32574,32575,32576,32577,32578,32579,32580,32581,32582,32583,32584,32585,32586,32587,32588,32589,32590,32591,32592,32593)) -- PO and data bundle
order by a.account_no, b.subscr_no, f.primary_list_price, e.offer_type, b.active_dt, b.offer_id asc;


with duplicate_ext_id as (
	SELECT subscr_no FROM customer_id_equip_map_view@cust1 ciem
	WHERE 1=1
	AND ciem.external_id_type = 91
	GROUP BY ciem.subscr_no
	HAVING Count(DISTINCT external_id) > 1
), subscribers as (
----1. Backdated Late PO (1st query to get all subscribers)
	select
	oiv.subscr_no
	from offer_inst_view@cust1 oiv, offer_ref@cust1 oref, reseller_version@cust1 rv, cmf@cust1 a
	where oiv.offer_id = oref.offer_id
	AND oiv.parent_account_no = a.account_no
	and oref.offer_type = 2
	and oref.equip_type_code = 101
	and oref.reseller_version_id = rv.reseller_version_id
	and rv.reseller_id = 7 -- M1 reseller
	and rv.inactive_date is null -- active reseller version
	and rv.status in (3) -- production should always be 3 PROPAGATED
	and oiv.view_status = 2 and oiv.chg_who = 'prod4acn' -- Provision by Web+/OSM 
	and oiv.inactive_dt is null -- Active
	and oiv.chg_dt > oiv.active_dt + 16.5/24
	AND oiv.chg_dt >= To_Date('20150429','yyyymmdd')
	--AND oiv.chg_dt < To_Date('20150505','yyyymmdd')
	AND NOT EXISTS ( select 1 from temp_subscriber where subscr_no = oiv.subscr_no)
	---------To check CBP
	AND EXISTS ( select 1 from duplicate_ext_id where oiv.subscr_no = subscr_no )
	---------To check CDR exists between Late PO period
	AND EXISTS (
		select 1
		from cdr_unbilled@cust1 b, cdr_data@cust1 a -- tarrif_plan_offer_id
		where a.msg_id = b.msg_id AND a.msg_id2 = b.msg_id2
		and a.split_row_num = b.split_row_num
		and a.initial_aut_id in (1284,1286,1287,1293,1295,1297,1298,1300,1302,1303,1304,1305,1307)
		AND a.trans_dt >= oiv.active_dt
		AND a.trans_dt < Trunc(oiv.chg_dt + 1)
		AND b.subscr_no = oiv.subscr_no
	)
) select distinct
(select distinct first_value(external_id) over (order by active_date desc, inactive_date desc nulls first) from customer_id_acct_map@cust1 where (account_no = b.account_no or account_no = b.parent_account_no) and is_current = 1 and external_id_type = 1) account, 
(select distinct first_value(external_id) over (order by active_date desc, inactive_date desc nulls first, external_id_type asc) from customer_id_equip_map_view@cust1 where subscr_no = b.subscr_no and view_status = 2 and external_id_type in (21,22,101,181,191,151,221)) service,
a.bill_period, a.prev_bill_refno, a.account_no, b.subscr_no,
(select sv.display_value from subscriber_status@cust1 ss, status_values@cust1 sv where ss.status_id = sv.status_id and ss.subscr_no = b.subscr_no and ss.inactive_dt is null) subscr_status,
b.offer_id, '"'||f.display_value||'"', f.primary_list_price, e.foreign_code, e.offer_type, b.offer_inst_id, b.chg_who, b.chg_dt, b.active_dt, b.inactive_dt,
decode(b.active_dt, b.inactive_dt, 'Cancelled', NULL) Cancelled,
'NO ACTION (Take note)' REMARK
from offer_inst_view@cust1 b, offer_ref@cust1 e, offer_values@cust1 f, reseller_version@cust1 g, cmf@cust1 a
where b.offer_id = e.offer_id and e.offer_id = f.offer_id
and e.reseller_version_id = f.reseller_version_id
and e.reseller_version_id = g.reseller_version_id
and g.reseller_id = 7 -- M1 reseller
and g.status in (3) -- production should always be 3 PROPAGATED
and b.view_status = 2
and ((a.account_no = b.account_no) or (a.account_no = b.parent_account_no))
and exists ( select 1 from subscribers where subscr_no = b.subscr_no )
and (e.offer_type = 2 or b.offer_id in (
	3140,3137,3136,3168,3169,3170,3177,3178,3195,3134,3138,3154,3155,3158,3161,3134,3138,3154,3155,3158,3161,3168,3169,3170,3177,3178,3195,3129,3135,3139,3157,3154,3158,3170,3178,3129,3135,3139,3157,3134,3138,3154,3155,3158,3161,3129,3135,3139,3157,3168,3169,3170,3177,3178,3195,3134,3138,3154,3155,3158,3161,3154,3158,3155,3129,3135,3139,3157,3134,3161,3138,3168,3169,3170,3177,3178,3195,3134,3138,3154,3155,3158,3161,3129,3135,3139,3157,3129,3134,3135,3138,3139,3155,3157,3161,3168,3169,3177,3195,3168,3169,3170,3177,3178,3195,3168,3169,3170,3177,3178,3195,3129,3135,3139,3157,3129,3135,3139,3157,3134,3138,3154,3155,3158,3161,3129,3135,3139,3157,3168,3169,3170,3177,3178,3195,3134,3138,3154,3155,3158,3161,3177,3178,3195,3134,3138,3154,3155,3158,3161,3168,3169,3170,3177,3178,3195,3129,3135,3139,3157,3168,3169,3170,3134,3138,3154,3155,3158,3161,3129,3135,3139,3157,3168,3169,3170,3177,3178,3195,3129,3135,3139,3157,3154,3155,3158,3161,3134,3138,3177,3178,3195,3168,3169,3170,3134,3135,3154,3155,3157,3158,3968,26497,3129,3195,9977,9979,
	3134,3135,3154,3155,3157,3158,3968,26497,3129,3195,9977,9979,3968,3154,10624,26497,7971,3135,3155,4038,3720,3721,3722,30369,30370,30397,30398,3198,3186,3199,3187,31249,31250,31251,32539,32540,32541,32570,32571,32572,32573,32574,32575,32576,32577,32578,32579,32580,32581,32582,32583,32584,32585,32586,32587,32588,32589,32590,32591,32592,32593)) -- PO and data bundle
order by a.account_no, b.subscr_no, f.primary_list_price, e.offer_type, b.active_dt, b.offer_id asc;



drop table temp_subscriber;