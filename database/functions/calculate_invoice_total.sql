-- calculate_invoice_total(invoice_id) -> void
-- Serves: BILLING (finalize). Recomputes sub_total from line items, applies 7% tax,
-- respects discount, updates the invoice. Result always satisfies chk_invoice_math.
CREATE OR REPLACE FUNCTION calculate_invoice_total(p_invoice_id INT)
RETURNS void AS $$
DECLARE v_sub DECIMAL(10,2); v_tax DECIMAL(10,2); v_disc DECIMAL(10,2);
BEGIN
  SELECT COALESCE(SUM(amount),0) INTO v_sub FROM invoice_item WHERE invoice_id = p_invoice_id;
  SELECT COALESCE(discount,0) INTO v_disc FROM invoice WHERE invoice_id = p_invoice_id;
  v_tax := ROUND(v_sub * 0.07, 2);
  UPDATE invoice SET sub_total = v_sub, tax_amount = v_tax,
         total_amount = v_sub + v_tax - v_disc
  WHERE invoice_id = p_invoice_id;
END; $$ LANGUAGE plpgsql;
