CREATE OR REPLACE FUNCTION check_transfer_limits()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.current_opens >= NEW.max_opens THEN
    NEW.status := 'destroyed';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_enforce_transfer_limits
BEFORE UPDATE OF current_opens ON transfers
FOR EACH ROW
EXECUTE FUNCTION check_transfer_limits();