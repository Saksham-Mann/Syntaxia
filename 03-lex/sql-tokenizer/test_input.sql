-- Sample SQL Benchmark File for Testing sql_tokenizer
-- Testing DDL, DML, joins, subqueries, operators, and comments

/* Multi-line table definition block
   Verifies data types, primary keys, and constraints */
CREATE TABLE employees (
    id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    salary DECIMAL(10, 2) DEFAULT 0.00,
    hire_date DATE,
    department_id INT REFERENCES departments(dept_id)
);

-- Query with aggregations, JOINs, WHERE filtering, and ordering
SELECT 
    e.id,
    e.first_name || ' ' || e.last_name AS full_name,
    d.dept_name,
    e.salary * 1.10 AS projected_salary
FROM employees AS e
INNER JOIN departments AS d ON e.department_id = d.dept_id
WHERE e.salary >= 45000.50 
  AND (e.department_id IN (1, 2, 3) OR e.department_id IS NULL)
  AND e.last_name LIKE 'S%'
GROUP BY e.id, d.dept_name
HAVING COUNT(*) > 1
ORDER BY projected_salary DESC
LIMIT 10 OFFSET 0;

/* Insert record with escaped quote */
INSERT INTO employees (first_name, last_name, salary)
VALUES ('O\'Connor', 'Developer', 85000);
