/*
데이터 집계 (2)
*/


-- 데이터베이스 연결
USE hrdb2019;
/*
RANK
DENSE_RANK
ROW_NUMBER
NTILE
*/


-- 1) RANK: 1, 2, 2, 4

-- 전제 순위 조회
SELECT emp_id, emp_name, dept_id, gender, phone, salary,
       RANK() OVER(ORDER BY salary DESC) AS rnk
   FROM employee
   WHERE retire_date IS NULL;
   
-- 남녀별 순위 조회
SELECT emp_id, emp_name, dept_id, gender, phone, salary,
       RANK() OVER(PARTITION BY gender ORDER BY salary DESC) AS rnk
   FROM employee
   WHERE retire_date IS NULL;


-- Q) 남녀별 1등 조회


   
   
-- 2) DENSE_RANK: 1, 2, 2, 3

-- 전체 순위 조회
SELECT emp_id, emp_name, dept_id, gender, phone, salary, 
	   DENSE_RANK() OVER(ORDER BY salary DESC) AS rnk
   FROM employee
   WHERE retire_date IS NULL;

-- 남녀별 순위 조회
SELECT emp_id, emp_name, dept_id, gender, phone, salary, 
	   DENSE_RANK() OVER(PARTITION BY gender ORDER BY salary DESC) AS rnk
   FROM employee
   WHERE retire_date IS NULL;


-- 3) ROW_NUMBER: 1, 2, 3, 4

-- 번호 붙여 조회
SELECT ROW_NUMBER() OVER(ORDER BY emp_id ASC) AS num,
       emp_id, emp_name, dept_id, gender, phone, salary
   FROM employee
   WHERE retire_date IS NULL;

-- 남녀별 번호 붙여 조회
SELECT ROW_NUMBER() OVER(PARTITION BY gender ORDER BY emp_id ASC) AS num,
	   emp_id, emp_name, dept_id, gender, phone, salary
   FROM employee
   WHERE retire_date IS NULL;


-- Q) 남녀 1번부터 3번까지 조회 : 서브 쿼리(서브 쿼리에는 order by를 사용하지 못 한다.)
select * from (SELECT ROW_NUMBER() OVER(PARTITION BY gender ORDER BY emp_id ASC) AS num,
	   emp_id, emp_name, dept_id, gender, phone, salary
   FROM employee
   WHERE retire_date IS NULL) as RN
where RN.num <= 3;

-- 4) NTILE: 1, 1, 1, 2, 2, 2, 3, 3, 3

-- 급여 순으로 3등분 
SELECT emp_id, emp_name, dept_id, gender, phone, salary,
	   NTILE(3) OVER(ORDER BY salary DESC) AS grp
   FROM employee
   WHERE retire_date IS NULL;
   
-- 1, 2, 3을 상, 중, 하로 바꾸기
SELECT emp_id, emp_name, dept_id, gender, phone, salary,
	   ELT(NTILE(3) OVER(ORDER BY salary DESC), '상', '중', '하') AS grp
   FROM employee
   WHERE retire_date IS NULL;

-- 남녀별 급여순으로 3등분
SELECT emp_id, emp_name, dept_id, gender, phone, salary,
	   NTILE(3) OVER(PARTITION BY gender ORDER BY salary DESC) AS grp
   FROM employee
   WHERE retire_date IS NULL;
   
-- OVER()
SELECT emp_name, dept_id, gender, salary, COUNT(*) OVER() AS cnt
FROM employee
WHERE retire_date IS NULL AND salary > 0;
-- 만약 OVER()를 안 쓰면 서브쿼리를 사용해서 작성해야함

-- OVER() #2 이동평균
SELECT emp_name, dept_id, gender, salary, 
	COUNT(*) OVER(ORDER BY emp_name) AS cnt, 
	SUM(salary) OVER(ORDER BY emp_name) AS tot_salary, 
	AVG(salary) OVER(ORDER BY emp_name) AS avg_salary
FROM employee
WHERE retire_date IS NULL AND salary > 0;


-- OVER() #3 누적합
SELECT emp_name, dept_id, gender, salary, 
	COUNT(*) OVER(PARTITION BY dept_id ORDER BY emp_name) AS cnt, 
	SUM(salary) OVER(PARTITION BY dept_id ORDER BY emp_name) AS tot_salary, 
	AVG(salary) OVER(PARTITION BY dept_id ORDER BY emp_name) AS avg_salary
FROM employee
WHERE retire_date IS NULL AND salary > 0;