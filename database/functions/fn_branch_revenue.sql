-- fn_branch_revenue(branch_id) -> TABLE
-- Serves: MANAGER dashboard. Monthly revenue for a branch (reads MonthlyRevenueReport MV).
CREATE OR REPLACE FUNCTION fn_branch_revenue(p_branch_id INT)
RETURNS TABLE(branch_name VARCHAR, year INT, month INT, invoices BIGINT, revenue NUMERIC) AS $$
  SELECT branch_name, year, month, invoice_count, total_revenue
  FROM MonthlyRevenueReport WHERE branch_id = p_branch_id
  ORDER BY year, month;
$$ LANGUAGE sql;
