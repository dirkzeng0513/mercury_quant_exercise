-- 2.aa.	In September, the five states with the highest average balance per customer were
-- Utah, Michigan, California, Washington, and Massachusetts.
-- Which of these states should we prioritize for marketing / advertising. Why?

-- create a calendar table to get monthly spending/balance view
---- refer to add_monthly_calendar_table view
-- get master dataset

-- The overall idea is to leverage all the data we have (spending up to Jan-21, balance up to Sep-19)
-- to develop an approximate growth potential index (also accounting for the fact that 2020 could be an anomaly)
-- 2019 spending_growth_rank * 0.4 + 2020 spending_growth_rank*0.8 + Jan 2021 spending *0.8


with cte_master_data as (
  select distinct dr.*,
         cal.the_month,
         COALESCE(bal.available_balance, 0) as available_balance,
         COALESCE(spnd.debit_card_spend_that_month, 0) as debit_card_spend_that_month
    from organization_data dr
    left join calendar_table cal
    on cast(cal.the_month as date) BETWEEN '2019-04-01' :: date and '2021-01-01'::date
    left join monthly_account_balances bal
    on dr.organization_id = bal.organization_id
    and cal.the_month = bal.the_month
    left join monthly_debit_card_spend spnd
    on dr.organization_id = spnd.organization_id
    and cal.the_month = spnd.the_month),



-- Calculate balance, spending over balance ratio for the five states, MOM

cte_state_summary as (
  select the_month,
         region_or_state,
         sum(available_balance) as monthly_bal,
         sum(debit_card_spend_that_month) as monthy_spnd,
         count(distinct organization_id) as monthly_customer_cnt
    from cte_master_data
    group by 1,2),


-- calcualte next-month,rolling 3-month, 6-month day spending
cte_spnd_pattern as (
  select the_month,
         region_or_state,
         -- the following 1-month/4-month spending
         monthly_bal,
         monthy_spnd,
         monthly_customer_cnt,
         sum(monthy_spnd) OVER (PARTITION by region_or_state order by the_month asc rows between 1 following and 2 following) as following_month_spnd,
         sum(monthly_customer_cnt) OVER (PARTITION by region_or_state order by the_month asc rows between 1 following and 2 following) as following_month_customer_cnt,
  	     sum(monthy_spnd) OVER (PARTITION by region_or_state order by the_month asc rows between 1 following and 4 following) as following_4_month_spnd,
         sum(monthly_customer_cnt) OVER (PARTITION by region_or_state order by the_month asc rows between 1 following and 4 following) as following_4_month_customer_cnt
    from cte_state_summary),



cte_sep_top_bal_summary as (
select region_or_state,
       the_month,
       monthy_spnd,
       monthy_spnd/monthly_customer_cnt as avg_mthly_customer_spnd,
       (following_month_spnd)/following_month_customer_cnt as avg_following_1_mth_customer_spend,
       (following_4_month_spnd)/following_4_month_customer_cnt as avg_following_4_mth_customer_spend
  from cte_spnd_pattern
 -- where upper(region_or_state) in ('UT','MI','CA','WA','MA', 'TX' ,'TN','NV','IL', 'NY')
  WHERE the_month in ('2019-09-01'::DATE, '2020-09-01'::Date)),



-- latest spending data as of 2021-01-01
  cte_jan_21_summary as (
    select region_or_state,
    	   monthy_spnd as monthly_spnd_202101
      from cte_state_summary
    -- where upper(region_or_state) in ('UT','MI','CA','WA','MA', 'TX' ,'TN','NV','IL','NY')
      where the_month = '2021-01-01' :: DATE),

  -- summary data for 'UT','MI','CA','WA','MA'
  -- we use the following metrics to make priority decison
  ---- 1. 2020 and 2019 per customer spending change month-over-month, over 3-month, and over 5-monthdemo
  ---- 2. Jan 2021 total customer spending

  cte_spnd_growth_summary as (
  select dr.region_or_state,
         dr.the_month,
         st.monthly_spnd_202101 as tot_monthly_spnd_202101,
         dr.avg_following_1_mth_customer_spend*1.0/NULLIF(dr.avg_mthly_customer_spnd, 0) as mom_spnd_chng,
         dr.avg_following_4_mth_customer_spend*1.0/NULLIF(dr.avg_mthly_customer_spnd, 0) as ovr_4mth_spnd_chng
    from cte_sep_top_bal_summary as dr
    left join cte_jan_21_summary st
    on dr.region_or_state = st.region_or_state),
  --where dr.region_or_state in ('UT','MI','CA','WA','MA','TX','TN','NV','IL','NY')),


   -- develop the grwoth index base data (rank one-month, three-month, and five-month spending growth pattern relative to Sep spending)
   cte_sep_spnd_growth_rank_summary as (
     select region_or_state,
        	the_month as reference_month,
     		tot_monthly_spnd_202101,
     		mom_spnd_chng,
            ovr_4mth_spnd_chng,
            -- defautl NULL/No spending data to 99
            rank()over(partition by the_month order by COALESCe(tot_monthly_spnd_202101, -99) asc) as jan_21_spnd_rnk,
            rank()over(partition by the_month order by COALESCE(mom_spnd_chng,-99) asc) as mom_spnd_chng_rnk,
     		rank()over(partition by the_month order by COALESCE(ovr_4mth_spnd_chng,-99) asc) as ovr_4mth_spnd_chng_rnk
       from cte_spnd_growth_summary),

   -- develop the grwoth index, and taking potential anomalie of 2020 into account
   -- (2019 growth_rank * 0.4 + 2020 growth_rank*0.8 + Jan 2021 spending *0.1)

   cte_growth_index as (
     select region_or_state,
            reference_month,
            tot_monthly_spnd_202101,
            case when reference_month = '2019-09-01'::date then 0.4*(mom_spnd_chng_rnk + ovr_4mth_spnd_chng_rnk)
                 when reference_month = '2020-09-01'::date then 0.8*(mom_spnd_chng_rnk + ovr_4mth_spnd_chng_rnk + jan_21_spnd_rnk)
                 else 0 end as growth_index
       from cte_sep_spnd_growth_rank_summary)

   -- final growth potential index ranked by state
    select region_or_state,
           tot_monthly_spnd_202101,
           sum(growth_index) as overall_growth_index
      from cte_growth_index
      where region_or_state in ('UT','MI','CA','WA','MA','TX','TN','NV','IL','NY')
      group by 1,2
      order by 3 DESC
