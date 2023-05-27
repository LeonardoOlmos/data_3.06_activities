-- Leonardo Olmos Saucedo / Activity 3.06 SQL

-- 1. Use a CTE to display the first account opened by a district.
with CTE_ACCOUNT as (
	select A.ACCOUNT_ID, A.`date` as OPENED_DATE, A.DISTRICT_ID, RANK() over (partition by A.DISTRICT_ID order by A.`date`) as `RANK`
	from ACCOUNT A
)
select *
from CTE_ACCOUNT 
where CTE_ACCOUNT.`RANK` = 1
order by CTE_ACCOUNT.DISTRICT_ID;


-- 2. In order to spot possible fraud, we want to create a view last_week_withdrawals with total withdrawals by client in the last week.
create or replace view last_week_withdrawals as 
	select T.ACCOUNT_ID, COUNT(T.TRANS_ID) as TOTAL_WITHDRAWALS
	from TRANS T 
	where T.`type` = 'VYDAJ'
	and T.`date` >= (
		select max(`date`) - INTERVAL 7 day
		from TRANS T 
	)
	and T.`date` <= (
		select MAX(T.`date`)
		from TRANS T
	)
	group by T.ACCOUNT_ID;


select * from last_week_withdrawals;

/* 3. The table client has a field birth_number that encapsulates client birthday and sex. 
 * The number is in the form YYMMDD for men, and in the form YYMM+50DD for women, where YYMMDD is the date of birth. 
 * Create a view client_demographics with client_id, birth_date and sex fields. Use that view and a CTE to find the number of loans by status and sex.
*/
create or replace view client_demographics as
select S2.CLIENT_ID, convert(CONCAT('19', S2.BIRTH_DATE), DATE) as BIRTH_DATE, S2.SEX
from (
	select S1.CLIENT_ID, CONCAT(left(S1.BIRTH_NUMBER, 2), 
	case when 
		length(S1.BIRTH_MONTH) = 1 then CONCAT('0', S1.BIRTH_MONTH)
		else S1.BIRTH_MONTH
	end, RIGHT(S1.BIRTH_NUMBER, 2)) as BIRTH_DATE, S1.SEX
	from (
		select C.CLIENT_ID, C.BIRTH_NUMBER, case
			when convert(SUBSTRING(convert(C.BIRTH_NUMBER, NCHAR), 3, 2), SIGNED) > 12 then 'F'
			else 'M'
		end as 'SEX',
		case
			when convert(SUBSTRING(convert(C.BIRTH_NUMBER, NCHAR), 3, 2), SIGNED) > 12 then convert(SUBSTRING(convert(C.BIRTH_NUMBER, NCHAR), 3, 2), SIGNED) - 50
			else convert(SUBSTRING(convert(C.BIRTH_NUMBER, NCHAR), 3, 2), SIGNED)
		end as 'BIRTH_MONTH'
	from CLIENT C) as S1) as S2;
	
with CTE_LOANS_BY_SEX as ( 
	select A.ACCOUNT_ID, L.LOAN_ID, L.STATUS, C.CLIENT_ID 
	from ACCOUNT A 
	join DISP D 
	on A.ACCOUNT_ID = D.DISP_ID 
	join CLIENT C 
	on D.CLIENT_ID = C.CLIENT_ID 
	join LOAN L 
	on L.ACCOUNT_ID = A.ACCOUNT_ID 
)


-- 4. Select loans greater than the average in their district.
with CTE_AVG_DISTRICT as (
	select D.A1 as DISTRICT_ID, avg(L.AMOUNT) as AVG_AMOUNT
	from LOAN L
	join ACCOUNT A 
	on L.ACCOUNT_ID = A.ACCOUNT_ID 
	join DISTRICT D 
	on A.DISTRICT_ID = D.A1 
	group by D.A1)
select L.LOAN_ID, L.AMOUNT, A.DISTRICT_ID, CTE.DISTRICT_ID, CTE.AVG_AMOUNT
from CTE_AVG_DISTRICT CTE
join ACCOUNT A 
on A.DISTRICT_ID = CTE.DISTRICT_ID
join LOAN L 
on L.ACCOUNT_ID = A.ACCOUNT_ID 
where L.AMOUNT > CTE.AVG_AMOUNT;