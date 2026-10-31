ALTER TABLE transfers ENABLE ROW LEVEL SECURITY;
ALTER TABLE transfer_contents ENABLE ROW LEVEL SECURITY;
ALTER TABLE groups ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Owners can view their own transfers"
ON transfers FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Owners can insert transfers"
ON transfers FOR INSERT
WITH CHECK (auth.uid() = user_id OR user_id IS NULL);