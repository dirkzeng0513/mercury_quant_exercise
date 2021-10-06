-- create a calendar tabledemo

-- get month range
-- 2019-04-01 2019-09-01
select min(the_month),
       max(the_month)
  from monthly_account_balances;

-- 2019-05-01 2021-01-01
select min(the_month),
       max(the_month)
  from monthly_debit_card_spend

CREATE TABLE calendar_table(
   the_month DATE NOT NULL
);
INSERT INTO calendar_table(the_month) VALUES ('2019-04-01');
INSERT INTO calendar_table(the_month) VALUES ('2019-05-01');
INSERT INTO calendar_table(the_month) VALUES ('2019-06-01');
INSERT INTO calendar_table(the_month) VALUES ('2019-07-01');
INSERT INTO calendar_table(the_month) VALUES ('2019-08-01');
INSERT INTO calendar_table(the_month) VALUES ('2019-09-01');
INSERT INTO calendar_table(the_month) VALUES ('2019-10-01');
INSERT INTO calendar_table(the_month) VALUES ('2019-11-01');
INSERT INTO calendar_table(the_month) VALUES ('2019-12-01');
INSERT INTO calendar_table(the_month) VALUES ('2020-01-01');
INSERT INTO calendar_table(the_month) VALUES ('2020-02-01');
INSERT INTO calendar_table(the_month) VALUES ('2020-03-01');
INSERT INTO calendar_table(the_month) VALUES ('2020-04-01');
INSERT INTO calendar_table(the_month) VALUES ('2020-05-01');
INSERT INTO calendar_table(the_month) VALUES ('2020-06-01');
INSERT INTO calendar_table(the_month) VALUES ('2020-07-01');
INSERT INTO calendar_table(the_month) VALUES ('2020-08-01');
INSERT INTO calendar_table(the_month) VALUES ('2020-09-01');
INSERT INTO calendar_table(the_month) VALUES ('2020-10-01');
INSERT INTO calendar_table(the_month) VALUES ('2020-11-01');
INSERT INTO calendar_table(the_month) VALUES ('2020-12-01');
INSERT INTO calendar_table(the_month) VALUES ('2021-01-01');