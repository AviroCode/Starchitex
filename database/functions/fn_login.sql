-- fn_login(username, password) -> INT
-- Serves: LOGIN screen. Returns 0 = success, 1 = bad credentials.
CREATE OR REPLACE FUNCTION fn_login(p_username VARCHAR, p_password VARCHAR)
RETURNS INT AS $$
DECLARE v_ok BOOLEAN;
BEGIN
  SELECT (password_hash = crypt(p_password, password_hash)) INTO v_ok
  FROM employee_credentials WHERE username = p_username;
  IF v_ok IS TRUE THEN RETURN 0; ELSE RETURN 1; END IF;
END; $$ LANGUAGE plpgsql;
