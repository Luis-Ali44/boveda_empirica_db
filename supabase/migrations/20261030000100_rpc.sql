CREATE OR REPLACE FUNCTION process_transfer_opening(p_access_code TEXT)
RETURNS TABLE(transfer_id UUID, is_valid BOOLEAN, updated_status TEXT) AS $$
DECLARE
  v_transfer transfers%ROWTYPE;
BEGIN
  SELECT * INTO v_transfer
  FROM transfers
  WHERE access_code = p_access_code
  FOR UPDATE;

  IF NOT FOUND OR v_transfer.status = 'destroyed' OR v_transfer.expires_at < NOW() THEN
    RETURN QUERY SELECT v_transfer.id, false, v_transfer.status;
    RETURN;
  END IF;

  UPDATE transfers
  SET current_opens = current_opens + 1
  WHERE id = v_transfer.id
  RETURNING status INTO v_transfer.status;

  RETURN QUERY SELECT v_transfer.id, true, v_transfer.status;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;