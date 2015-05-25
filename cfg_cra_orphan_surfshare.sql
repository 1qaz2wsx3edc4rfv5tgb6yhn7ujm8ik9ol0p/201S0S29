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
select 'STATUS','EXT_ACCOUNT','SERVICE','ACCOUNT_NO','SUBSCR_NO','ACTIVE_DT','INACTIVE_DT','CHG_DT','CHG_WHO','BILL_PERIOD','REMARKS' from dual;

 --New Active Orphan List Only with Unbilled Usage
select 'Active' as status, 
(select distinct first_value(external_id) over (order by active_date desc, inactive_date desc nulls first) from customer_id_acct_map@cust1 where (account_no = oiv.account_no or account_no = oiv.parent_account_no) and is_current = 1 and external_id_type = 1) ext_account, 
(select distinct first_value(external_id) over (order by active_date desc, inactive_date desc nulls first, external_id_type asc) from customer_id_equip_map_view@cust1 where subscr_no = oiv.subscr_no and view_status = 2 and external_id_type in (21,22,101,181,191,151,221)) service,
oiv.parent_account_no as account_no, 
oiv.subscr_no, active_dt, inactive_dt, chg_dt, chg_who, (select bill_period from cmf@cust1 where account_no = oiv.parent_account_no) bill_period,
case when (select count(*) from cdr_unbilled@cust1 cu, cdr_data@cust1 cd 
                        where cu.subscr_no = oiv.subscr_no and cu.msg_id = cd.msg_id and cu.msg_id2 = cd.msg_id2 and cd.point_target = 'SUNSURF') > 0  
          then 'with unbilled LDC (' ||(select min(cu.trans_dt) from cdr_unbilled@cust1 cu, cdr_data@cust1 cd where cu.subscr_no = oiv.subscr_no and cu.msg_id = cd.msg_id and cu.msg_id2 = cd.msg_id2 and cd.point_target = 'SUNSURF')
                      ||' - '|| (select max(cu.trans_dt) from cdr_unbilled@cust1 cu, cdr_data@cust1 cd where cu.subscr_no = oiv.subscr_no and cu.msg_id = cd.msg_id and cu.msg_id2 = cd.msg_id2 and cd.point_target = 'SUNSURF') ||')'                                  
  else null end as remarks
from offer_inst_view@cust1 oiv             
where oiv.view_status = 2 and oiv.offer_id in (102506) 
and not exists (select 1 from offer_inst_view@cust1 a where a.view_status = 2 and a.offer_id in (115052,115053,115054,115060,115061,115062,115114,115115,115116,115117,115122,115123,115124,115125) and a.parent_account_no = oiv.parent_account_no)
and not exists (select 1 from offer_inst_view@cust1 a where a.view_status = 2 and a.offer_id in (31249,31250,31251,32539,32540,32541,32570,32571,32572,32573,32574,32575,32576,32577,32578,32579,32580,32581,32582,32583,32584,32585,32586,32587,32588,32589,32590,32591,32592,32593) 
  and a.account_no = oiv.parent_account_no) 
and chg_who = 'prod4acn' and active_dt > '11/Dec/2014'  and inactive_dt is null
/* only selecting active orphans with or without the data usage
and exists (select 1 from cdr_unbilled@cust1 cu, cdr_data@cust1 cd where cu.subscr_no = oiv.subscr_no
                      and cu.msg_id = cd.msg_id and cu.msg_id2 = cd.msg_id2 and cd.point_target = 'SUNSURF')*/                      
--order by chg_who desc, chg_dt desc;    --Apr22 Scan Count = 0
--order by 9 desc, chg_dt desc;    --Apr22 Scan Count = 0
Union 
--Disconnected Orphan List Only - Created in WEB+ with Unbilled Usage
select 'Terminated' as status, (select distinct external_id from customer_id_acct_map@cust1 where (account_no = oiv.account_no or account_no = oiv.parent_account_no)  /*and inactive_date is null*/ and is_current = 1 and external_id_type = 1) ext_account, 
oiv.parent_account_no as account_no,
(select distinct max(external_id) from customer_id_equip_map_view@cust1 where subscr_no = oiv.subscr_no and is_current = 0 and view_status = 2 /* and inactive_dt is null */and external_id_type in (21,22,181,191,151,221)) service, 
oiv.subscr_no, active_dt, inactive_dt, chg_dt, chg_who, (select bill_period from cmf@cust1 where account_no = oiv.parent_account_no) bill_period ,
case when (select count(*) from cdr_unbilled@cust1 cu, cdr_data@cust1 cd 
                        where cu.subscr_no = oiv.subscr_no and cu.msg_id = cd.msg_id and cu.msg_id2 = cd.msg_id2 and cd.point_target = 'SUNSURF') > 0  
          then 'with unbilled LDC (' ||(select distinct min(cu.trans_dt) from cdr_unbilled@cust1 cu, cdr_data@cust1 cd where cu.subscr_no = oiv.subscr_no and cu.msg_id = cd.msg_id and cu.msg_id2 = cd.msg_id2 and cd.point_target = 'SUNSURF')
                      ||' - '|| (select distinct max(cu.trans_dt) from cdr_unbilled@cust1 cu, cdr_data@cust1 cd where cu.subscr_no = oiv.subscr_no and cu.msg_id = cd.msg_id and cu.msg_id2 = cd.msg_id2 and cd.point_target = 'SUNSURF') ||')'                                  
  else null end as remarks
from offer_inst_view@cust1 oiv
where oiv.view_status = 2 and oiv.offer_id in (102506) 
and not exists (select 1 from offer_inst_view@cust1 a where a.view_status = 2 and a.offer_id in (115052,115053,115054,115060,115061,115062,115114,115115,115116,115117,115122,115123,115124,115125) and a.parent_account_no = oiv.parent_account_no)
and not exists (select 1 from offer_inst_view@cust1 a where a.view_status = 2 and a.offer_id in (31249,31250,31251,32539,32540,32541,32570,32571,32572,32573,32574,32575,32576,32577,32578,32579,32580,32581,32582,32583,32584,32585,32586,32587,32588,32589,32590,32591,32592,32593) 
  and a.account_no = oiv.parent_account_no) 
and chg_who = 'prod4acn' and active_dt > '11/Dec/2014'  and inactive_dt is not null
and exists (select 1 from cmf@cust1 where account_no = oiv.parent_account_no and no_bill = 0) --exclude those with no_bill = 1
and oiv.inactive_dt > (select nvl(trunc(prev_cutoff_date),add_months(trunc(next_bill_date)-14,-1)) from cmf@cust1 where account_no = oiv.parent_account_no and no_bill = 0)  ---pulling only changes covered by the next BC
/*and exists (select 1 from cdr_unbilled@cust1 cu, cdr_data@cust1 cd where cu.subscr_no = oiv.subscr_no ---with unbilled LDC
                      and cu.msg_id = cd.msg_id and cu.msg_id2 = cd.msg_id2 and cd.point_target = 'SUNSURF')*/
--order by chg_dt desc, bill_period, oiv.parent_account_no; 
order by 1, 10 desc, chg_dt asc;    