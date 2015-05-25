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
select 'EXT_ACCOUNT_NO', 'BILL_PERIOD', 'ACCOUNT_NO', 'COUNT_DISC', 'OFFER_ID', 'ACTIVE_DT', 'INACTIVE_DT', 'PRIMARY_LIST_PRICE', 'DESCRIPTION', 'OFFER_INST_ID', 'COUNT_PARENTLN' from dual;

WITH overlaps AS (
SELECT external_id ext_account_no,cmf.bill_period ,a.* ,d.OFFER_ID,c.active_dt,c.inactive_dt,PRIMARY_LIST_PRICE , DESCRIPTION ,c.offer_inst_id
FROM (
SELECT account_no,Count(*) count_disc
FROM (
SELECT c.account_no,c.bill_period,a.offer_id, PRIMARY_LIST_PRICE ,  DESCRIPTION ,a.inactive_dt
FROM cmf c,offer_values@cust1 b,offer_inst_view@cust1 a
WHERE a.offer_id=b.offer_id AND a.account_no=c.account_no AND b.reseller_version_id=45 AND view_status=2 AND
a.active_dt!=Nvl(a.inactive_dt,a.active_dt+1) AND a.offer_id IN (
SELECT opmap.offer_id FROM OFFER_BT_PROMO_PLAN_MAP@cust1 opmap ,BT_PROMOTION_PLAN_ITEM_MAP@cust1 pdmap
WHERE opmap.bt_promotion_plan_id=pdmap.bt_promotion_plan_id  AND  opmap.RESELLER_VERSION_ID=45 AND pdmap.RESELLER_VERSION_ID=45 and 
pdmap.discount_id IN (
SELECT discount_id FROM BT_DISCOUNT_ITEM_REF@cust1 a WHERE discount_level=2 AND SAVE_DETAIL=1 AND RESELLER_VERSION_ID=45
AND (discount_domain=3 OR
  (EXISTS (SELECT 1 FROM bt_discount_restrictions@cust1 b WHERE b.discount_id=a.discount_id AND RESTRICTION_TYPE=5 AND RESTRICTED_DOMAIN=3 AND
  RESELLER_VERSION_ID=45)
  )
) ))  AND Nvl(a.inactive_dt,SYSDATE) >=to_date('20150201','yyyymmdd')
) GROUP  BY account_no HAVING Count(*)>1
) a,customer_id_acct_map b ,offer_inst_view@cust1 c,offer_values@cust1 d,cmf
WHERE cmf.account_no=a.account_no AND a.account_no=b.account_no AND external_id_type=1 AND
c.account_no=a.account_no AND c.view_status=2 AND d.offer_id=c.offer_id AND d.reseller_version_id=45 AND c.active_dt!=Nvl(c.inactive_dt,c.active_dt+1)  AND
Nvl(c.inactive_dt,SYSDATE) >=to_date('20150201','yyyymmdd') and
 c.offer_id IN (
SELECT opmap.offer_id FROM OFFER_BT_PROMO_PLAN_MAP@cust1 opmap ,BT_PROMOTION_PLAN_ITEM_MAP@cust1 pdmap
WHERE opmap.bt_promotion_plan_id=pdmap.bt_promotion_plan_id  AND  opmap.RESELLER_VERSION_ID=45 AND pdmap.RESELLER_VERSION_ID=45 
and pdmap.discount_id IN (
SELECT discount_id FROM BT_DISCOUNT_ITEM_REF@cust1 a WHERE discount_level=2 AND SAVE_DETAIL=1 AND RESELLER_VERSION_ID=45
AND (discount_domain=3 OR
  (EXISTS (SELECT 1 FROM bt_discount_restrictions@cust1 b WHERE b.discount_id=a.discount_id AND RESTRICTION_TYPE=5 AND RESTRICTED_DOMAIN=3 AND
  RESELLER_VERSION_ID=45)
  )
))
) )
SELECT a.*,
(SELECT Count(*) FROM offer_inst_view@cust1 x
WHERE x.parent_account_no=a.account_no AND view_status=2 AND
inactive_dt IS NULL AND
offer_id IN (
115052	,115053	,115054	,115056	,115057	,115058	,115060	,115061	,115062	,
115064	,115065	,115066	,115114	,115115	,115116	,115117	,115122	,115123	,
115124	,115125	 
)) Count_parentln
FROM overlaps a
WHERE DESCRIPTION LIKE '%SurfShare%' AND
EXISTS (SELECT 1 FROM overlaps b WHERE b.account_no=a.account_no AND b.DESCRIPTION LIKE '%SurfShare%' AND  a.OFFER_INST_ID!=b.OFFER_INST_ID and
        (
          (a.active_dt+1<Nvl(b.inactive_dt,SYSDATE) AND Nvl(a.inactive_dt,sysdate)>active_dt+1 )
        )
) UNION ALL
SELECT a.*,null
FROM overlaps a
WHERE DESCRIPTION LIKE '%SunShare%' AND
EXISTS (SELECT 1 FROM overlaps b WHERE b.account_no=a.account_no AND b.DESCRIPTION LIKE '%SunShare%' AND  a.OFFER_INST_ID!=b.OFFER_INST_ID and
        (
          (a.active_dt+1<Nvl(b.inactive_dt,SYSDATE) AND Nvl(a.inactive_dt,sysdate)>active_dt+1 )
        )
);

