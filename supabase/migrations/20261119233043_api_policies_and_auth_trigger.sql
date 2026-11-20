-- Permitir que la API inserte y consulte transferencias.
DROP POLICY IF EXISTS "Permitir insertar transferencias" ON transfers;
CREATE POLICY "Permitir insertar transferencias"
ON transfers FOR INSERT
WITH CHECK (true);

DROP POLICY IF EXISTS "Permitir consultar transferencias" ON transfers;
CREATE POLICY "Permitir consultar transferencias"
ON transfers FOR SELECT
USING (true);

-- Permitir que la API inserte y consulte contenidos de transferencias.
DROP POLICY IF EXISTS "Permitir insertar contenidos" ON transfer_contents;
CREATE POLICY "Permitir insertar contenidos"
ON transfer_contents FOR INSERT
WITH CHECK (true);

DROP POLICY IF EXISTS "Permitir leer contenidos" ON transfer_contents;
CREATE POLICY "Permitir leer contenidos"
ON transfer_contents FOR SELECT
USING (true);

-- Copiar el usuario autenticado a la tabla publica users al registrarse.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.users (id, email)
  VALUES (NEW.id, NEW.email);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();
