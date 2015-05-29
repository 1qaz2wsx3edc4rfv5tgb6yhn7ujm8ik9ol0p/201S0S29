header:set head off
header:set pagesize 0
header:set linesize 20000
header:set trimspool on
header:set trim on
header:set colsep ","

/* creating temp table */
-- 4g 3g vas misaligned do separately
create table bundle as (
-- GSM original
select 102044 offer_id, 'po' offer_type, 'gsm' datagrp, '102044 - iPhone Value' bundletype from dual union
select 102060 offer_id, 'po' offer_type, 'gsm' datagrp, '102060 - ValueSurf' bundletype from dual union
select 102061 offer_id, 'po' offer_type, 'gsm' datagrp, '102061 - LiteSurf' bundletype from dual union
select 102045 offer_id, 'po' offer_type, 'gsm' datagrp, '102045 - iPhone Lite' bundletype from dual union
select 102073 offer_id, 'po' offer_type, 'gsm' datagrp, '102073 - mData Lite' bundletype from dual union
select 102074 offer_id, 'po' offer_type, 'gsm' datagrp, '102073 - mData Lite' bundletype from dual union
select 102066 offer_id, 'po' offer_type, 'gsm' datagrp, '102066 - mData Student' bundletype from dual union
select 102066 offer_id, 'po' offer_type, 'gsm' datagrp, '102078 - mData Student (wef 1 Sep 11)' bundletype from dual
-- GSM old data         
union                   
select 102037 offer_id, 'po' offer_type, 'gsm' datagrp, 'gsm data' bundletype from dual union
select 102100 offer_id, 'po' offer_type, 'gsm' datagrp, 'gsm data' bundletype from dual union
select 115007 offer_id, 'po' offer_type, 'gsm' datagrp, 'gsm data' bundletype from dual union
select 115008 offer_id, 'po' offer_type, 'gsm' datagrp, 'gsm data' bundletype from dual union
select 115009 offer_id, 'po' offer_type, 'gsm' datagrp, 'gsm data' bundletype from dual union
select 115010 offer_id, 'po' offer_type, 'gsm' datagrp, 'gsm data' bundletype from dual union
select 115015 offer_id, 'po' offer_type, 'gsm' datagrp, 'gsm data' bundletype from dual union
select 115016 offer_id, 'po' offer_type, 'gsm' datagrp, 'gsm data' bundletype from dual union
select 115017 offer_id, 'po' offer_type, 'gsm' datagrp, 'gsm data' bundletype from dual union
select 115018 offer_id, 'po' offer_type, 'gsm' datagrp, 'gsm data' bundletype from dual union
select 115023 offer_id, 'po' offer_type, 'gsm' datagrp, 'gsm data' bundletype from dual union
select 115028 offer_id, 'po' offer_type, 'gsm' datagrp, 'gsm data' bundletype from dual union
select 115029 offer_id, 'po' offer_type, 'gsm' datagrp, 'gsm data' bundletype from dual union
select 115034 offer_id, 'po' offer_type, 'gsm' datagrp, 'gsm data' bundletype from dual union
select 115035 offer_id, 'po' offer_type, 'gsm' datagrp, 'gsm data' bundletype from dual union
select 115036 offer_id, 'po' offer_type, 'gsm' datagrp, 'gsm data' bundletype from dual union
select 115042 offer_id, 'po' offer_type, 'gsm' datagrp, 'gsm data' bundletype from dual union
select 115043 offer_id, 'po' offer_type, 'gsm' datagrp, 'gsm data' bundletype from dual
-- gsm new data       
union                 
select 115090 offer_id, 'po' offer_type, 'gsm' datagrp, 'gsm data' bundletype from dual union
select 115091 offer_id, 'po' offer_type, 'gsm' datagrp, 'gsm data' bundletype from dual union
select 115092 offer_id, 'po' offer_type, 'gsm' datagrp, 'gsm data' bundletype from dual union
select 115093 offer_id, 'po' offer_type, 'gsm' datagrp, 'gsm data' bundletype from dual union
select 115094 offer_id, 'po' offer_type, 'gsm' datagrp, 'gsm data' bundletype from dual union
select 115095 offer_id, 'po' offer_type, 'gsm' datagrp, 'gsm data' bundletype from dual union
select 115102 offer_id, 'po' offer_type, 'gsm' datagrp, 'gsm data' bundletype from dual union
select 115103 offer_id, 'po' offer_type, 'gsm' datagrp, 'gsm data' bundletype from dual union
select 115104 offer_id, 'po' offer_type, 'gsm' datagrp, 'gsm data' bundletype from dual union
select 115105 offer_id, 'po' offer_type, 'gsm' datagrp, 'gsm data' bundletype from dual union
select 115106 offer_id, 'po' offer_type, 'gsm' datagrp, 'gsm data' bundletype from dual union
select 115107 offer_id, 'po' offer_type, 'gsm' datagrp, 'gsm data' bundletype from dual 
-- mdata bundle        
union                  
select 102091 offer_id, 'po' offer_type, 'mdata' datagrp, 'mData' bundletype from dual union
select 115001 offer_id, 'po' offer_type, 'mdata' datagrp, 'mData' bundletype from dual union
select 115002 offer_id, 'po' offer_type, 'mdata' datagrp, 'mData' bundletype from dual union
select 115003 offer_id, 'po' offer_type, 'mdata' datagrp, 'mData' bundletype from dual union
select 115004 offer_id, 'po' offer_type, 'mdata' datagrp, 'mData' bundletype from dual union
select 115005 offer_id, 'po' offer_type, 'mdata' datagrp, 'mData' bundletype from dual union
select 115006 offer_id, 'po' offer_type, 'mdata' datagrp, 'mData' bundletype from dual union
select 115039 offer_id, 'po' offer_type, 'mdata' datagrp, 'mData' bundletype from dual union
select 115047 offer_id, 'po' offer_type, 'mdata' datagrp, 'mData' bundletype from dual union
select 115048 offer_id, 'po' offer_type, 'mdata' datagrp, 'mData' bundletype from dual union
select 115070 offer_id, 'po' offer_type, 'mdata' datagrp, 'mData' bundletype from dual 
-- surfshare bundle    
union                  
select 115052 offer_id, 'po' offer_type, 'surfshare' datagrp, '115052 - SurfShare iPhone Value+' bundletype from dual union
select 115053 offer_id, 'po' offer_type, 'surfshare' datagrp, '115053 - SurfShare iPhone Lite+' bundletype from dual union
select 115054 offer_id, 'po' offer_type, 'surfshare' datagrp, '115054 - SurfShare iPhone Extreme+' bundletype from dual union
select 115060 offer_id, 'po' offer_type, 'surfshare' datagrp, '115060 - SurfShare ValueSurf+' bundletype from dual union 
select 115061 offer_id, 'po' offer_type, 'surfshare' datagrp, '115061 - SurfShare LiteSurf+' bundletype from dual union
select 115062 offer_id, 'po' offer_type, 'surfshare' datagrp, '115062 - SurfShare ExtremeSurf+' bundletype from dual union
select 115114 offer_id, 'po' offer_type, 'surfshare' datagrp, '115114 - SurfShare i-Lite+' bundletype from dual union
select 115115 offer_id, 'po' offer_type, 'surfshare' datagrp, '115115 - SurfShare i-Reg' bundletype from dual union
select 115116 offer_id, 'po' offer_type, 'surfshare' datagrp, '115116 - SurfShare i-Reg+' bundletype from dual union
select 115117 offer_id, 'po' offer_type, 'surfshare' datagrp, '115117 - SurfShare i-Max' bundletype from dual union
select 115122 offer_id, 'po' offer_type, 'surfshare' datagrp, '115122 - SurfShare Lite+' bundletype from dual union
select 115123 offer_id, 'po' offer_type, 'surfshare' datagrp, '115123 - SurfShare Reg' bundletype from dual union
select 115124 offer_id, 'po' offer_type, 'surfshare' datagrp, '115124 - SurfShare Reg+' bundletype from dual union
select 115125 offer_id, 'po' offer_type, 'surfshare' datagrp, '115125 - SurfShare Max' bundletype from dual union
-- gsm original
select 3134 offer_id, 'so' offer_type, 'gsm' datagrp, '102044 - iPhone Value' bundletype from dual union
select 3138 offer_id, 'so' offer_type, 'gsm' datagrp, '102044 - iPhone Value' bundletype from dual union
select 3154 offer_id, 'so' offer_type, 'gsm' datagrp, '102060 - ValueSurf' bundletype from dual union
select 3157 offer_id, 'so' offer_type, 'gsm' datagrp, '102060 - ValueSurf' bundletype from dual union
select 3155 offer_id, 'so' offer_type, 'gsm' datagrp, '102061 - LiteSurf' bundletype from dual union
select 3158 offer_id, 'so' offer_type, 'gsm' datagrp, '102061 - LiteSurf' bundletype from dual union
select 3135 offer_id, 'so' offer_type, 'gsm' datagrp, '102045 - iPhone Lite' bundletype from dual union
select 3139 offer_id, 'so' offer_type, 'gsm' datagrp, '102045 - iPhone Lite' bundletype from dual union
select 3968 offer_id, 'so' offer_type, 'gsm' datagrp, '102073 - mData Lite' bundletype from dual union
select 3161 offer_id, 'so' offer_type, 'gsm' datagrp, '102066 - mData Student' bundletype from dual union
select 3178 offer_id, 'so' offer_type, 'gsm' datagrp, '102078 - mData Student (wef 1 Sep 11)' bundletype from dual
-- gsm old/new data  
union                
select 30369 offer_id, 'so' offer_type, '3g' datagrp, 'gsm data' bundletype from dual union
select 30370 offer_id, 'so' offer_type, '4g' datagrp, 'gsm data' bundletype from dual union
select 30397 offer_id, 'so' offer_type, '3g' datagrp, 'gsm data' bundletype from dual union
select 30398 offer_id, 'so' offer_type, '4g' datagrp, 'gsm data' bundletype from dual 
-- mdata bundle
union
select 3186 offer_id, 'so' offer_type, '3g' datagrp, 'mData' bundletype from dual union
select 3187 offer_id, 'so' offer_type, '4g' datagrp, 'mData' bundletype from dual union
select 3198 offer_id, 'so' offer_type, '3g' datagrp, 'mData' bundletype from dual union
select 3199 offer_id, 'so' offer_type, '4g' datagrp, 'mData' bundletype from dual
-- surfshare bundle
union
select 32539 offer_id, 'so' offer_type, 'surfshare' datagrp, '115052 - SurfShare iPhone Value+' bundletype from dual union
select 32540 offer_id, 'so' offer_type, 'surfshare' datagrp, '115053 - SurfShare iPhone Lite+' bundletype from dual union
select 32541 offer_id, 'so' offer_type, 'surfshare' datagrp, '115054 - SurfShare iPhone Extreme+' bundletype from dual union
select 31249 offer_id, 'so' offer_type, 'surfshare' datagrp, '115060 - SurfShare ValueSurf+' bundletype from dual union
select 31250 offer_id, 'so' offer_type, 'surfshare' datagrp, '115061 - SurfShare LiteSurf+' bundletype from dual union
select 31251 offer_id, 'so' offer_type, 'surfshare' datagrp, '115062 - SurfShare ExtremeSurf+' bundletype from dual union
select 32570 offer_id, 'so' offer_type, 'surfshare' datagrp, '115114 - SurfShare i-Lite+' bundletype from dual union
select 32578 offer_id, 'so' offer_type, 'surfshare' datagrp, '115114 - SurfShare i-Lite+' bundletype from dual union
select 32586 offer_id, 'so' offer_type, 'surfshare' datagrp, '115114 - SurfShare i-Lite+' bundletype from dual union
select 32571 offer_id, 'so' offer_type, 'surfshare' datagrp, '115115 - SurfShare i-Reg' bundletype from dual union
select 32579 offer_id, 'so' offer_type, 'surfshare' datagrp, '115115 - SurfShare i-Reg' bundletype from dual union
select 32587 offer_id, 'so' offer_type, 'surfshare' datagrp, '115115 - SurfShare i-Reg' bundletype from dual union
select 32572 offer_id, 'so' offer_type, 'surfshare' datagrp, '115116 - SurfShare i-Reg+' bundletype from dual union
select 32580 offer_id, 'so' offer_type, 'surfshare' datagrp, '115116 - SurfShare i-Reg+' bundletype from dual union
select 32588 offer_id, 'so' offer_type, 'surfshare' datagrp, '115116 - SurfShare i-Reg+' bundletype from dual union
select 32573 offer_id, 'so' offer_type, 'surfshare' datagrp, '115117 - SurfShare i-Max' bundletype from dual union
select 32581 offer_id, 'so' offer_type, 'surfshare' datagrp, '115117 - SurfShare i-Max' bundletype from dual union
select 32589 offer_id, 'so' offer_type, 'surfshare' datagrp, '115117 - SurfShare i-Max' bundletype from dual union
select 32574 offer_id, 'so' offer_type, 'surfshare' datagrp, '115122 - SurfShare Lite+' bundletype from dual union
select 32582 offer_id, 'so' offer_type, 'surfshare' datagrp, '115122 - SurfShare Lite+' bundletype from dual union
select 32590 offer_id, 'so' offer_type, 'surfshare' datagrp, '115122 - SurfShare Lite+' bundletype from dual union
select 32575 offer_id, 'so' offer_type, 'surfshare' datagrp, '115123 - SurfShare Reg' bundletype from dual union
select 32583 offer_id, 'so' offer_type, 'surfshare' datagrp, '115123 - SurfShare Reg' bundletype from dual union
select 32591 offer_id, 'so' offer_type, 'surfshare' datagrp, '115123 - SurfShare Reg' bundletype from dual union
select 32576 offer_id, 'so' offer_type, 'surfshare' datagrp, '115124 - SurfShare Reg+' bundletype from dual union
select 32584 offer_id, 'so' offer_type, 'surfshare' datagrp, '115124 - SurfShare Reg+' bundletype from dual union
select 32592 offer_id, 'so' offer_type, 'surfshare' datagrp, '115124 - SurfShare Reg+' bundletype from dual union
select 32577 offer_id, 'so' offer_type, 'surfshare' datagrp, '115125 - SurfShare Max' bundletype from dual union
select 32585 offer_id, 'so' offer_type, 'surfshare' datagrp, '115125 - SurfShare Max' bundletype from dual union
select 32593 offer_id, 'so' offer_type, 'surfshare' datagrp, '115125 - SurfShare Max' bundletype from dual union
-- 4g vas
select 4038 offer_id, 'vas' offer_type, '4g' datagrp, 'vas' bundletype from dual union
select 7971 offer_id, 'vas' offer_type, '4g' datagrp, 'vas' bundletype from dual
);

CREATE TABLE subscriberlist as
  select distinct account_no, parent_account_no, subscr_no, subscr_no_resets, max(offer_id) keep (dense_rank first order by active_dt desc, inactive_dt desc) latest_offer, 
  offer_type, datagrp, bundletype, max(chg_dt) chg_dt,
  min(active_dt) start_dt, --keep (dense_rank first order by active_dt asc, inactive_dt asc nulls last) start_dt, 
  max(inactive_dt) keep (dense_rank first order by active_dt desc, inactive_dt desc nulls first) end_dt
  from (
    select account_no, parent_account_no, subscr_no, subscr_no_resets, offer_id, active_dt, inactive_dt, offer_type, datagrp, bundletype, 
    max(chg_dt) over (partition by account_no, subscr_no, offer_type, datagrp, bundletype) chg_dt,
    max(grp) over (order by account_no, subscr_no, offer_type, active_dt desc, inactive_dt desc nulls first) grp from (
      select oiv.account_no, oiv.parent_account_no, oiv.subscr_no, oiv.subscr_no_resets, oiv.offer_id, active_dt, inactive_dt, chg_dt, so.offer_type, so.datagrp, so.bundletype,
      case
          when (trunc(oiv.inactive_dt) is null) 
            then row_number() over (order by account_no, subscr_no, offer_type, datagrp, active_dt desc, inactive_dt desc nulls first)
          when (trunc(oiv.inactive_dt) - trunc(lag(oiv.active_dt) over (order by account_no, subscr_no, offer_type, datagrp, active_dt desc, inactive_dt desc nulls first)) < 0) 
            then row_number() over (order by account_no, subscr_no, offer_type, datagrp, active_dt desc, inactive_dt desc nulls first)
          when (trunc(oiv.inactive_dt) - trunc(lag(oiv.active_dt) over (order by account_no, subscr_no, offer_type, datagrp, active_dt desc, inactive_dt desc nulls first)) > 1) 
            then row_number() over (order by account_no, subscr_no, offer_type, datagrp, active_dt desc, inactive_dt desc nulls first)
          when (
            (lag(bundletype) over (order by account_no, subscr_no, offer_type, datagrp, active_dt desc, inactive_dt desc nulls first) <> bundletype) and
            (lag(datagrp) over (order by account_no, subscr_no, offer_type, datagrp, active_dt desc, inactive_dt desc nulls first) <> datagrp)
          ) then row_number() over (order by account_no, subscr_no, offer_type, datagrp, active_dt desc, inactive_dt desc nulls first)
      end grp
      from offer_inst_view oiv, bundle so
      where 1=1
      --and subscr_no = 53770176
      and oiv.view_status = 2
      and ((oiv.active_dt <> oiv.inactive_dt and oiv.inactive_dt < sysdate) or oiv.inactive_dt is null)
      and oiv.offer_id = so.offer_id
      order by parent_account_no, subscr_no, subscr_no_resets, offer_type, datagrp, bundletype, grp, active_dt desc, inactive_dt desc nulls first
    )
  ) t 
  --where subscr_no = 53770176
  group by account_no, parent_account_no, subscr_no, subscr_no_resets, offer_type, datagrp, bundletype, grp, chg_dt
  order by start_dt desc, end_dt desc nulls first;
--) select * from subscriberlist2 where subscr_no = 58671498

create index idx_subscr on subscriberlist(subscr_no, subscr_no_resets) nologging;

commit;
/* end temp table part */