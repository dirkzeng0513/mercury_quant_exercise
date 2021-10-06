--1 a.	What was the total end of month balance for each month?
select
       cast(date_trunc('month',the_month) as date) as month,
	   sum(available_balance) as tot_mthly_bal
  from monthly_account_balances
  group by 1
  order by 1 asc


--1. b.What was the total debit card spend each month?
select
       cast(date_trunc('month',the_month) as date) as month,
	   sum(debit_card_spend_that_month) as tot_mthly_spnd
  from monthly_debit_card_spend
  group by 1
  order by 1 asc

--1.c Which industries had the highest average balances and debit card spend in September 2019?

 with global_variables as (
   select '2019-09-01' :: date as datetime
   ),

 cte_ind_bal_spnd as (
   select dr.industry,
          sum(COALESCE(bal.available_balance, 0)) as ind_bal,
          sum(COALESCE(spnd.debit_card_spend_that_month,0)) as ind_spnd
     from organization_data dr
     left join monthly_account_balances bal
     on dr.organization_id = bal.organization_id
     and bal.the_month = (SELECT datetime from global_variables)
     Left join monthly_debit_card_spend spnd
     on dr.organization_id = spnd.organization_id
     and spnd.the_month = (SELECT datetime from global_variables)
 	group by 1),

 -- rank summary table by balance and spending
 cte_ind_summary as (
   select industry,
          rank() over (order by ind_bal desc) as bal_rnk,
          rank() over (order by ind_spnd desc) as spnd_rnk
     from cte_ind_bal_spnd)

 select * from cte_ind_summary where bal_rnk = 1 or spnd_rnk = 1

--1.d What was the proportion of our users from California each month?
 -- define monthly active users with either balance or spending

 -- active bal acct
 with cte_act_bal_dr as (
   select organization_id,
   		  the_month
     from monthly_account_balances
    where available_balance is not NULL),

 -- acive spnd acct
 cte_act_spnd_dr as (
   select organization_id,
   		  the_month
     from monthly_debit_card_spend
    where debit_card_spend_that_month is not NULL),

 -- overall active acct driver
 cte_act_dr as (
   select mth.*
     from cte_act_bal_dr as mth
   union
   select spnd.*
     from cte_act_spnd_dr as spnd),

  -- get demograpic data
  cte_demog_data as (
    select dr.the_month,
    	   count(DISTINCT dr.organization_id) as mthly_act_user_cnt,
           count(DISTINCT case when upper(region_or_state) = 'CA' then dr.organization_id end) as mthly_ca_user_cnt
      from cte_act_dr dr
      left join organization_data demo
      on dr.organization_id = demo.organization_id
      group by 1)

  select the_month,
         (mthly_ca_user_cnt*1.0/mthly_act_user_cnt) as percent_ca_user
    from cte_demog_data
    order by 1 asc














