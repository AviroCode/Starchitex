-- fn_guest_folio(invoice_id) -> TABLE
-- Serves: BILLING screen (folio). Totals + amount paid + balance due.
CREATE OR REPLACE FUNCTION fn_guest_folio(p_invoice_id INT)
RETURNS TABLE(invoice_id INT, payer TEXT, sub_total DECIMAL, tax DECIMAL,
              discount DECIMAL, total DECIMAL, paid DECIMAL, balance DECIMAL, status VARCHAR) AS $$
  SELECT i.invoice_id, g.first_name || ' ' || g.last_name,
         i.sub_total, i.tax_amount, i.discount, i.total_amount,
         COALESCE((SELECT SUM(amount) FROM payment WHERE invoice_id = i.invoice_id), 0),
         i.total_amount - COALESCE((SELECT SUM(amount) FROM payment WHERE invoice_id = i.invoice_id), 0),
         i.status
  FROM invoice i
  JOIN guest g ON g.guest_id = i.payer_guest_id
  WHERE i.invoice_id = p_invoice_id;
$$ LANGUAGE sql;
