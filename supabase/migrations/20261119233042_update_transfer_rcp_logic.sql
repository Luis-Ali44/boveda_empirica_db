CREATE OR REPLACE FUNCTION process_transfer_opening(p_access_code TEXT)
RETURNS TABLE(transfer_id UUID, is_valid BOOLEAN, updated_status TEXT) AS $$
DECLARE
  v_transfer transfers%ROWTYPE;
  v_new_opens INT;
BEGIN
  -- 1. Obtener y bloquear el registro para evitar condiciones de carrera
  SELECT * INTO v_transfer
  FROM transfers
  WHERE access_code = p_access_code
  FOR UPDATE;

  -- 2. Si no existe, rechazamos
  IF NOT FOUND THEN
    RETURN QUERY SELECT NULL::UUID, false, NULL::TEXT;
    RETURN;
  END IF;

  -- 3. Si ya estaba destruida o su fecha expiró, asegurar estado y rechazar
  IF v_transfer.status = 'destroyed' OR v_transfer.expires_at < NOW() THEN
    IF v_transfer.status != 'destroyed' THEN
      UPDATE transfers SET status = 'destroyed' WHERE id = v_transfer.id;
    END IF;
    RETURN QUERY SELECT v_transfer.id, false, 'destroyed'::TEXT;
    RETURN;
  END IF;

  -- 4. Calcular el nuevo número de aperturas (usando COALESCE por si era NULL)
  v_new_opens := COALESCE(v_transfer.current_opens, 0) + 1;

  -- 5. Si con esta apertura alcanzamos el límite, la destruimos
  IF v_new_opens >= v_transfer.max_opens THEN
    UPDATE transfers
    SET current_opens = v_new_opens, status = 'destroyed'
    WHERE id = v_transfer.id;
    
    -- Devolvemos true ESTA VEZ porque es su última vida válida
    RETURN QUERY SELECT v_transfer.id, true, 'destroyed'::TEXT;
  ELSE
    -- Aún tiene vidas, solo actualizamos el contador
    UPDATE transfers
    SET current_opens = v_new_opens, status = COALESCE(v_transfer.status, 'active')
    WHERE id = v_transfer.id;
    
    RETURN QUERY SELECT v_transfer.id, true, v_transfer.status;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;