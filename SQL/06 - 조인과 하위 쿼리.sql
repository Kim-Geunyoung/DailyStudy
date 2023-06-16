/*
조인과 하위 쿼리
*/


-- 데이터베이스 연결
USE hrdb2019;

-- 조인 #1
-- 1단계 : 만남
select emp_name, emp_id, employee.dept_id, dept_name, gender, hire_date, salary
from employee
inner join department ON employee.dept_id = department.dept_id
where retire_date IS NULL;

-- 2단계 : 단순
select emp_name, emp_id, e.dept_id, dept_name, gender, hire_date, salary
from employee AS e
inner join department AS d ON e.dept_id = d.dept_id
where retire_date IS NULL;

-- 3단계 : 착함
select e.emp_name, e.emp_id, e.dept_id, d.dept_name, e.gender, e.hire_date, e.salary
from employee AS e
inner join department AS d ON e.dept_id = d.dept_id
where retire_date IS NULL;

-- 조인 #2
select v.emp_id, e.emp_name, e.gender, e.hire_date, v.begin_date, v.reason, v.duration
from vacation as v
inner join employee as e on v.emp_id = e.emp_id
where e.retire_date is null;

-- 조인 #3
select v.emp_id, e.emp_name, e.gender, e.hire_date, v.begin_date, v.reason, v.duration
from vacation as v
inner join employee as e on v.begin_date = e.hire_date
where e.retire_date is null;

-- 조인 #4
select v.emp_id, e.emp_name, d.dept_name, e.hire_date, v.begin_date, v.reason, v.duration
from vacation as v
inner join employee as e on v.emp_id = e.emp_id
inner join department as d on d.dept_id = e.dept_id
where e.retire_date is null;

-- 조인 #5
select v.emp_id, e.emp_name, d.dept_name, u.unit_name, 
	e.hire_date, v.begin_date, v.reason, v.duration
from vacation as v
inner join employee as e on v.emp_id = e.emp_id
inner join department as d on d.dept_id = e.dept_id
inner join unit as u on u.unit_id = d.unit_id
where e.retire_date is null;

-- 조인 #6
select e.emp_name, e.emp_id, e.hire_date, v.begin_date, v.reason, v.duration
from employee as e
inner join vacation as v on e.emp_id = v.emp_id
where retire_date is null;

-- 조인 #7
select d.dept_id, d.dept_name, u.unit_name
from department as d
inner join unit as u on u.unit_id = d.unit_id;

-- 조인 #8
-- left outer, right outer, full outer
-- inner
select d.dept_id, d.dept_name, u.unit_name
from department as d
left outer join unit as u on u.unit_id = d.unit_id;

-- 조인 #9
select e.emp_name, e.emp_id, e.hire_date, v.begin_date, v.reason, v.duration
from employee as e
left outer join vacation as v on e.emp_id = v.emp_id
where retire_date is null;

/*
INNER JOIN
OUTER JOIN : LEFT, RIGHT, FULL OUTER
CROSS JOIN : ON 절이 없다. 모든 경우의 수 만큼의 행이 만들어짐
*/

-- 조인 #10: 남자 직원의 휴가 현황(WHERE 절을 위한 조인이 필요할 수 있음)
select v.emp_id, v.begin_date, v.reason, v.duration
from vacation as v
inner join employee as e on e.emp_id = v.emp_id
where e.gender = 'M';


-- 1) 조인 작성 과정

-- 직원 정보 조회
SELECT emp_id, emp_name, dept_id, phone, email
	FROM employee 
	WHERE hire_date BETWEEN '2014-01-01' AND '2015-12-31' 
		AND retire_date IS NULL;

-- 조인 1단계
SELECT emp_id, emp_name, employee.dept_id, department.dept_name, phone, email
	FROM employee 
	JOIN department ON employee.dept_id = department.dept_id
	WHERE hire_date BETWEEN '2014-01-01' AND '2015-12-31' 
		AND retire_date IS NULL;

-- 조인 2단계
SELECT emp_id, emp_name, e.dept_id, d.dept_name, phone, email
	FROM employee AS e
	JOIN department AS d ON e.dept_id = d.dept_id
	WHERE hire_date BETWEEN '2014-01-01' AND '2015-12-31' 
		AND retire_date IS NULL;

-- 조인 3단계
SELECT e.emp_id, e.emp_name, e.dept_id, d.dept_name, e.phone, e.email
	FROM employee AS e
	JOIN department AS d ON e.dept_id = d.dept_id
	WHERE e.hire_date BETWEEN '2014-01-01' AND '2015-12-31' 
		AND e.retire_date IS NULL;
        
        
-- 2) INNER JOIN

/*
- 가장 일반적인 JOIN 문 형태
- 양쪽 테이블에서 비교되는 값이 일치하는 행만 가져옴
- 일반적으로 PK와 FK가 ON 절에서 서로 비교됨
*/

-- 직원 정보 조회
SELECT e.emp_id, e.emp_name, e.dept_id, d.dept_name, e.phone
	FROM employee AS e
	INNER JOIN department AS d ON e.dept_id = d.dept_id
	WHERE e.hire_date BETWEEN '2014-01-01' AND '2015-12-31' 
		AND e.retire_date IS NULL;

-- 휴가 정보 조회
SELECT e.emp_id, e.emp_name, v.begin_date, v.end_date, v.reason, v.duration
	FROM employee AS e
	INNER JOIN vacation AS v ON e.emp_id = v.emp_id
	WHERE e.hire_date BETWEEN '2015-01-01' AND '2016-12-31' 
		AND retire_date IS NULL
	ORDER BY e.emp_id ASC;

-- 부서 정보 조회
SELECT d.dept_id, d.dept_name, d.unit_id, u.unit_name, d.start_date
	FROM department AS d
	INNER JOIN unit AS u ON d.unit_id = u.unit_id;

-- 휴가 정보 조회
SELECT v.emp_id, e.emp_name, e.dept_id, e.phone, SUM(v.duration) AS Tot_duration
	FROM vacation AS v
	INNER JOIN employee AS e ON v.emp_id = e.emp_id
	WHERE v.begin_date BETWEEN '2017-01-01' AND '2017-06-30'
	GROUP BY v.emp_id, e.emp_name, e.dept_id, e.phone
	ORDER BY SUM(v.duration) DESC;


-- 3) OUTER JOIN

/*
- 비교되는 값이 일치하지 않는 행도 기준 테이블에서 가져옴
- LEFT OUTER JOIN, RIGHT OUTER JOIN, FULL OUTER JOIN 으로 구분
- 단, MySQL은 FULL OUTER JOIN 이 없음
*/

-- 휴가 정보 조회
SELECT e.emp_id, e.emp_name, v.begin_date, v.end_date, v.reason, v.duration
	FROM employee AS e 
	LEFT OUTER JOIN vacation AS v ON e.emp_id = v.emp_id
	WHERE e.hire_date BETWEEN '2015-01-01' AND '2016-12-31' 
		AND retire_date IS NULL
	ORDER BY e.emp_id ASC;

-- 부서 정보 조회
SELECT d.dept_id, d.dept_name, d.unit_id, u.unit_name
   FROM department AS d
   LEFT OUTER JOIN unit AS u ON d.unit_id = u.unit_id;

-- 여러 테이블 조회
SELECT e.emp_id, e.emp_name, d.dept_name, u.unit_name, 
       v.begin_date, v.duration
   FROM employee AS e
   INNER JOIN department AS d ON e.dept_id = d.dept_id
   LEFT OUTER JOIN unit AS u ON d.unit_id = u.unit_id
   INNER JOIN vacation AS v ON e.emp_id = v.emp_id
   WHERE v.begin_date BETWEEN '2017-01-01' AND '2017-03-31'
   ORDER BY e.emp_id ASC;


-- 4) CROSS JOIN

/*
- 일반적인 비즈니스 응용프로그램에서 사용되지 않음
- ON 절이 없어 모든 경우의 수만큼 결과 행을 얻음
- 대량의 테스트 데이터를 만드는 목적으로 많이 사용됨
*/

-- 직원과 부서간 CROSS JOIN
SELECT emp_name, dept_name
    FROM employee AS e
    CROSS JOIN department AS d;


-- Q) 부서 이름 다음에 본부 이름을 표시하도록 다음 쿼리문 수정

SELECT e.emp_id, e.emp_name, e.dept_id, d.dept_name, e.phone, e.email
	FROM employee AS e
	INNER JOIN department AS d ON e.dept_id = d.dept_id
	WHERE e.hire_date BETWEEN '2014-01-01' AND '2015-12-31' 
		AND e.retire_date IS NULL;


-- Q) 직원 이름 다음에 부서 이름을 표시하도록 다음 쿼리문 수정

SELECT e.emp_id, e.emp_name, v.begin_date, v.end_date, v.reason, v.duration
	FROM employee AS e
	INNER JOIN vacation AS v ON e.emp_id = v.emp_id
	WHERE e.hire_date BETWEEN '2015-01-01' AND '2016-12-31' 
		AND retire_date IS NULL
	ORDER BY e.emp_id ASC;


-- Q) 직원 이름 다음에 본부 이름을 표시하도록 다음 쿼리문 수정

SELECT e.emp_id, e.emp_name, v.begin_date, v.end_date, v.reason, v.duration
	FROM employee AS e
	INNER JOIN vacation AS v ON e.emp_id = v.emp_id
	WHERE e.hire_date BETWEEN '2015-01-01' AND '2016-12-31' 
		AND retire_date IS NULL
	ORDER BY e.emp_id ASC;

    
-- Q) 본부에 포함되지 않은 부서 정보를 조회하도록 다음 쿼리문 수정

SELECT d.dept_id, d.dept_name, d.unit_id, u.unit_name
   FROM department AS d
   LEFT OUTER JOIN unit AS u ON d.unit_id = u.unit_id;


-- 5) 하위 쿼리

/*
- 괄호 안에 또다른 쿼리문이 있는 쿼리문
- 대부분 JOIN 문으로 작성해서 같은 결과를 얻을 수 있음
- JOIN 문보다 작성하기가 쉬움
*/

-- 가장 급여를 많이 받는 직원
SELECT emp_id, emp_name, dept_id, phone, email, salary
	FROM employee
	WHERE salary = (SELECT MAX(salary) FROM employee);

-- 가장 먼저 입사한 직원
SELECT emp_id, emp_name, dept_id, phone, email, salary
	FROM employee
	WHERE hire_date = (SELECT MIN(hire_date) FROM employee);

-- 휴가를 간 적이 있는 정보시스템 직원
SELECT emp_id, emp_name, dept_id, phone, email
	FROM employee
	WHERE dept_id = 'SYS'
	AND emp_id IN (SELECT emp_id FROM vacation);

-- 휴가를 간 적이 없는 정보시스템 직원
SELECT emp_id, emp_name, dept_id, phone, email
	FROM employee
	WHERE dept_id = 'SYS'
	AND emp_id NOT IN (SELECT emp_id FROM vacation);


-- Q) 가장 최근에 퇴사한 직원 정보 조회

    
    
-- Q) 강우동(S0003)보다 급여를 많이 받는 직원 정보 조회


-- 6) 상관 하위 쿼리

/*
- 내부 쿼리(괄호 안에 있는 쿼리)가 독립적으로 수행되지 못함
- 외부 쿼리에서 넘겨진 값을 가지고 내부 쿼리가 수행됨
*/

-- 부서 이름을 포함한 근무중인 직원 정보 조회
SELECT emp_id, emp_name, dept_id, 
       (SELECT dept_name FROM department WHERE dept_id = e.dept_id) AS dept_name, 
       phone, email, salary
	FROM employee AS e
	WHERE retire_date IS NULL;
    
-- 휴가를 간 적이 있는 근무중인 직원 정보 조회
SELECT emp_id, emp_name, dept_id, phone, email, salary
	FROM employee AS e
	WHERE EXISTS (
        SELECT *
            FROM vacation
            WHERE emp_id = e.emp_id
    ) AND retire_date IS NULL;
    
-- Q) 휴가를 간 적이 없는 근무중인 직원 정보 조회
SELECT emp_id, emp_name, dept_id, phone, email, salary
	FROM employee AS e
	WHERE not EXISTS (
        SELECT *
            FROM vacation
            WHERE emp_id = e.emp_id
    ) AND retire_date IS NULL;
    
-- NOT LIKE
-- NOT IN
-- NOT BETWEEN
-- IS NOT NULL
-- NOT EXISTS
    
-- Q) 부서별로 급여를 가장 많이 맏는 근무중인 직원 정보 조회
select *
from employee as e
where salary = (select max(salary) from employee where retire_date is null and dept_id = e.dept_id) and retire_date is null;

