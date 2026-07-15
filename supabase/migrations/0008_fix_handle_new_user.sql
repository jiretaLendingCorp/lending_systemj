-- supabase/migrations/0008_fix_handle_new_user.sql

ALTER TABLE public.users DROP CONSTRAINT IF EXISTS users_email_key;
DROP INDEX IF EXISTS users_email_key;
DROP INDEX IF EXISTS idx_users_email_active;

CREATE UNIQUE INDEX idx_users_email_active
  ON public.users (email)
  WHERE deleted_at IS NULL;

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_full_name TEXT;
  v_role      user_role;
  v_existing_id UUID;
BEGIN
  v_full_name := COALESCE(
    NEW.raw_user_meta_data->>'full_name',
    NEW.raw_user_meta_data->>'name',
    split_part(NEW.email, '@', 1)
  );

  BEGIN
    v_role := COALESCE(
      (NEW.raw_app_meta_data->>'role')::user_role,
      'lender'::user_role
    );
  EXCEPTION WHEN invalid_text_representation THEN
    v_role := 'lender'::user_role;
  END;

  SELECT id INTO v_existing_id
  FROM public.users
  WHERE email = NEW.email
  FOR UPDATE;

  IF v_existing_id IS NOT NULL THEN
    IF v_existing_id = NEW.id THEN
      UPDATE public.users
      SET
        email      = NEW.email,
        full_name  = v_full_name,
        role       = v_role,
        is_active  = true,
        deleted_at = NULL,
        updated_at = now()
      WHERE id = NEW.id;
      RETURN NEW;
    END IF;

    DELETE FROM public.users WHERE id = v_existing_id;
  END IF;

  INSERT INTO public.users (id, email, full_name, role)
  VALUES (NEW.id, NEW.email, v_full_name, v_role)
  ON CONFLICT (id) DO UPDATE
    SET
      email      = EXCLUDED.email,
      full_name  = EXCLUDED.full_name,
      role       = EXCLUDED.role,
      is_active  = true,
      deleted_at = NULL,
      updated_at = now();

  RETURN NEW;
END;
$$;

ALTER FUNCTION public.handle_new_user() OWNER TO postgres;

DROP TRIGGER IF EXISTS trg_on_auth_user_created ON auth.users;
CREATE TRIGGER trg_on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

GRANT USAGE ON SCHEMA public TO authenticated, anon, service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.users TO service_role;

CREATE POLICY "service_role can manage users"
  ON public.users FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);
