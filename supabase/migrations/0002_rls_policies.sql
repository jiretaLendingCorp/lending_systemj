-- supabase/migrations/0002_rls_policies.sql
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE lenders ENABLE ROW LEVEL SECURITY;
ALTER TABLE co_makers ENABLE ROW LEVEL SECURITY;
ALTER TABLE lender_phones ENABLE ROW LEVEL SECURITY;
ALTER TABLE riders ENABLE ROW LEVEL SECURITY;
ALTER TABLE loans ENABLE ROW LEVEL SECURITY;
ALTER TABLE loan_co_makers ENABLE ROW LEVEL SECURITY;
ALTER TABLE loan_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE disbursements ENABLE ROW LEVEL SECURITY;
ALTER TABLE collections ENABLE ROW LEVEL SECURITY;
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE otp_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE idempotency_keys ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_settings ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.user_role()
RETURNS user_role AS $$
  SELECT (auth.jwt() -> 'app_metadata' ->> 'role')::user_role;
$$ LANGUAGE sql STABLE SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.is_head_manager()
RETURNS BOOLEAN AS $$
  SELECT public.user_role() = 'head_manager';
$$ LANGUAGE sql STABLE SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.is_employee()
RETURNS BOOLEAN AS $$
  SELECT public.user_role() = 'employee';
$$ LANGUAGE sql STABLE SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.is_rider()
RETURNS BOOLEAN AS $$
  SELECT public.user_role() = 'rider';
$$ LANGUAGE sql STABLE SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.is_lender()
RETURNS BOOLEAN AS $$
  SELECT public.user_role() = 'lender';
$$ LANGUAGE sql STABLE SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.current_user_id()
RETURNS UUID AS $$
  SELECT auth.uid();
$$ LANGUAGE sql STABLE SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.current_lender_id()
RETURNS UUID AS $$
  SELECT id FROM public.lenders WHERE user_id = public.current_user_id() AND deleted_at IS NULL LIMIT 1;
$$ LANGUAGE sql STABLE SECURITY DEFINER;

CREATE POLICY "Users can read own record"
  ON users FOR SELECT
  USING (id = public.current_user_id());

CREATE POLICY "Head Managers can read all users"
  ON users FOR SELECT
  USING (public.is_head_manager());

CREATE POLICY "Employees can read all users"
  ON users FOR SELECT
  USING (public.is_employee());

CREATE POLICY "Users can update own record"
  ON users FOR UPDATE
  USING (id = public.current_user_id() AND deleted_at IS NULL)
  WITH CHECK (id = public.current_user_id());

CREATE POLICY "Head Managers can delete users"
  ON users FOR DELETE
  USING (public.is_head_manager());

CREATE POLICY "Lenders can read own record"
  ON lenders FOR SELECT
  USING (
    user_id = public.current_user_id()
    AND deleted_at IS NULL
  );

CREATE POLICY "Employees and Head Managers can read all lenders"
  ON lenders FOR SELECT
  USING (
    (public.is_employee() OR public.is_head_manager())
    AND deleted_at IS NULL
  );

CREATE POLICY "Lenders can update own record"
  ON lenders FOR UPDATE
  USING (
    user_id = public.current_user_id()
    AND deleted_at IS NULL
  );

CREATE POLICY "Riders can read assigned lenders"
  ON lenders FOR SELECT
  USING (
    public.is_rider()
    AND deleted_at IS NULL
    AND (
      id IN (
        SELECT l.lender_id FROM loans l
        JOIN disbursements d ON d.loan_id = l.id
        WHERE d.assigned_rider_id IN (
          SELECT r.id FROM riders r WHERE r.user_id = public.current_user_id()
        )
      )
      OR id IN (
        SELECT c.lender_id FROM collections c
        WHERE c.assigned_rider_id IN (
          SELECT r.id FROM riders r WHERE r.user_id = public.current_user_id()
        )
      )
    )
  );

CREATE POLICY "Lenders can read own loans"
  ON loans FOR SELECT
  USING (
    lender_id IN (
      SELECT b.id FROM lenders b WHERE b.user_id = public.current_user_id()
    )
    AND deleted_at IS NULL
  );

CREATE POLICY "Employees and Head Managers can read all loans"
  ON loans FOR SELECT
  USING (
    (public.is_employee() OR public.is_head_manager())
    AND deleted_at IS NULL
  );

CREATE POLICY "Lenders can create loans"
  ON loans FOR INSERT
  WITH CHECK (
    lender_id IN (
      SELECT b.id FROM lenders b WHERE b.user_id = public.current_user_id()
    )
    AND deleted_at IS NULL
  );

CREATE POLICY "Employees and Head Managers can update loans"
  ON loans FOR UPDATE
  USING (
    (public.is_employee() OR public.is_head_manager())
    AND deleted_at IS NULL
  );

CREATE POLICY "Lenders can read own loan schedules"
  ON loan_schedules FOR SELECT
  USING (
    loan_id IN (
      SELECT l.id FROM loans l
      JOIN lenders b ON l.lender_id = b.id
      WHERE b.user_id = public.current_user_id()
    )
  );

CREATE POLICY "Employees and Head Managers can read all schedules"
  ON loan_schedules FOR SELECT
  USING (public.is_employee() OR public.is_head_manager());

CREATE POLICY "Lenders can read own payments"
  ON payments FOR SELECT
  USING (
    lender_id IN (
      SELECT b.id FROM lenders b WHERE b.user_id = public.current_user_id()
    )
    AND deleted_at IS NULL
  );

CREATE POLICY "Employees and Head Managers can read all payments"
  ON payments FOR SELECT
  USING (
    (public.is_employee() OR public.is_head_manager())
    AND deleted_at IS NULL
  );

CREATE POLICY "Lenders can create payments"
  ON payments FOR INSERT
  WITH CHECK (
    lender_id IN (
      SELECT b.id FROM lenders b WHERE b.user_id = public.current_user_id()
    )
  );

CREATE POLICY "Lenders can read own disbursements"
  ON disbursements FOR SELECT
  USING (
    loan_id IN (
      SELECT l.id FROM loans l
      JOIN lenders b ON l.lender_id = b.id
      WHERE b.user_id = public.current_user_id()
    )
    AND deleted_at IS NULL
  );

CREATE POLICY "Riders can read assigned disbursements"
  ON disbursements FOR SELECT
  USING (
    assigned_rider_id IN (
      SELECT r.id FROM riders r WHERE r.user_id = public.current_user_id()
    )
    AND deleted_at IS NULL
  );

CREATE POLICY "Employees and Head Managers can read all disbursements"
  ON disbursements FOR SELECT
  USING (
    (public.is_employee() OR public.is_head_manager())
    AND deleted_at IS NULL
  );

CREATE POLICY "Riders can update assigned disbursements"
  ON disbursements FOR UPDATE
  USING (
    assigned_rider_id IN (
      SELECT r.id FROM riders r WHERE r.user_id = public.current_user_id()
    )
    AND deleted_at IS NULL
  );

CREATE POLICY "Lenders can read own collections"
  ON collections FOR SELECT
  USING (
    lender_id IN (
      SELECT b.id FROM lenders b WHERE b.user_id = public.current_user_id()
    )
    AND deleted_at IS NULL
  );

CREATE POLICY "Riders can read assigned collections"
  ON collections FOR SELECT
  USING (
    assigned_rider_id IN (
      SELECT r.id FROM riders r WHERE r.user_id = public.current_user_id()
    )
    AND deleted_at IS NULL
  );

CREATE POLICY "Employees and Head Managers can read all collections"
  ON collections FOR SELECT
  USING (
    (public.is_employee() OR public.is_head_manager())
    AND deleted_at IS NULL
  );

CREATE POLICY "Riders can update assigned collections"
  ON collections FOR UPDATE
  USING (
    assigned_rider_id IN (
      SELECT r.id FROM riders r WHERE r.user_id = public.current_user_id()
    )
    AND deleted_at IS NULL
  );

CREATE POLICY "Lenders can read own documents"
  ON documents FOR SELECT
  USING (
    lender_id IN (
      SELECT b.id FROM lenders b WHERE b.user_id = public.current_user_id()
    )
    AND deleted_at IS NULL
  );

CREATE POLICY "Employees and Head Managers can read all documents"
  ON documents FOR SELECT
  USING (
    (public.is_employee() OR public.is_head_manager())
    AND deleted_at IS NULL
  );

CREATE POLICY "Lenders can create documents"
  ON documents FOR INSERT
  WITH CHECK (
    lender_id IN (
      SELECT b.id FROM lenders b WHERE b.user_id = public.current_user_id()
    )
  );

CREATE POLICY "Employees and Head Managers can update documents"
  ON documents FOR UPDATE
  USING (
    (public.is_employee() OR public.is_head_manager())
    AND deleted_at IS NULL
  );

CREATE POLICY "Users can read own notifications"
  ON notifications FOR SELECT
  USING (user_id = public.current_user_id());

CREATE POLICY "Users can update own notifications"
  ON notifications FOR UPDATE
  USING (user_id = public.current_user_id());

CREATE POLICY "No direct access to OTP codes"
  ON otp_codes FOR ALL
  USING (false)
  WITH CHECK (false);

CREATE POLICY "Head Managers can read audit logs"
  ON audit_logs FOR SELECT
  USING (public.is_head_manager());

CREATE POLICY "No direct access to idempotency keys"
  ON idempotency_keys FOR ALL
  USING (false)
  WITH CHECK (false);

CREATE POLICY "Head Managers can read system settings"
  ON system_settings FOR SELECT
  USING (public.is_head_manager());

CREATE POLICY "Head Managers can update system settings"
  ON system_settings FOR UPDATE
  USING (public.is_head_manager());

CREATE POLICY "Lenders can read own co-makers"
  ON co_makers FOR SELECT
  USING (
    id IN (
      SELECT lcm.co_maker_id FROM loan_co_makers lcm
      JOIN loans l ON lcm.loan_id = l.id
      JOIN lenders b ON l.lender_id = b.id
      WHERE b.user_id = public.current_user_id()
    )
  );

CREATE POLICY "Employees and Head Managers can read all co-makers"
  ON co_makers FOR SELECT
  USING (public.is_employee() OR public.is_head_manager());

CREATE POLICY "Lenders can read own phones"
  ON lender_phones FOR SELECT
  USING (
    lender_id IN (
      SELECT b.id FROM lenders b WHERE b.user_id = public.current_user_id()
    )
  );

CREATE POLICY "Employees and Head Managers can read all lender phones"
  ON lender_phones FOR SELECT
  USING (public.is_employee() OR public.is_head_manager());

CREATE POLICY "Riders can read own record"
  ON riders FOR SELECT
  USING (
    user_id = public.current_user_id()
    AND deleted_at IS NULL
  );

CREATE POLICY "Employees and Head Managers can read all riders"
  ON riders FOR SELECT
  USING (
    (public.is_employee() OR public.is_head_manager())
    AND deleted_at IS NULL
  );

CREATE POLICY "Riders can update own record"
  ON riders FOR UPDATE
  USING (
    user_id = public.current_user_id()
    AND deleted_at IS NULL
  );

CREATE POLICY "Lenders can read own loan co-makers"
  ON loan_co_makers FOR SELECT
  USING (
    loan_id IN (
      SELECT l.id FROM loans l
      JOIN lenders b ON l.lender_id = b.id
      WHERE b.user_id = public.current_user_id()
    )
  );

CREATE POLICY "Employees and Head Managers can read all loan co-makers"
  ON loan_co_makers FOR SELECT
  USING (public.is_employee() OR public.is_head_manager());
