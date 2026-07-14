-- ============================================================================
-- LendFlow: Row-Level Security Policies
-- Migration 0002_rls_policies.sql
-- ============================================================================

-- Enable RLS on all application tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE borrowers ENABLE ROW LEVEL SECURITY;
ALTER TABLE co_makers ENABLE ROW LEVEL SECURITY;
ALTER TABLE borrower_phones ENABLE ROW LEVEL SECURITY;
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

-- ═══════════════════════════════════════════════════════════════════════════
-- Helper: Check if the current user has a specific role
-- ═══════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION auth.user_role()
RETURNS user_role AS $$
  SELECT (auth.jwt() -> 'app_metadata' ->> 'role')::user_role;
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION auth.is_admin()
RETURNS BOOLEAN AS $$
  SELECT auth.user_role() = 'admin';
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION auth.is_manager()
RETURNS BOOLEAN AS $$
  SELECT auth.user_role() = 'manager';
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION auth.is_rider()
RETURNS BOOLEAN AS $$
  SELECT auth.user_role() = 'rider';
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION auth.is_borrower()
RETURNS BOOLEAN AS $$
  SELECT auth.user_role() = 'borrower';
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION auth.current_user_id()
RETURNS UUID AS $$
  SELECT auth.uid();
$$ LANGUAGE sql STABLE;

-- ═══════════════════════════════════════════════════════════════════════════
-- Users
-- ═══════════════════════════════════════════════════════════════════════════

-- Everyone can read their own record
CREATE POLICY "Users can read own record"
  ON users FOR SELECT
  USING (id = auth.current_user_id());

-- Admins can read all users
CREATE POLICY "Admins can read all users"
  ON users FOR SELECT
  USING (auth.is_admin());

-- Managers can read all users
CREATE POLICY "Managers can read all users"
  ON users FOR SELECT
  USING (auth.is_manager());

-- Users can update their own record (limited fields)
CREATE POLICY "Users can update own record"
  ON users FOR UPDATE
  USING (id = auth.current_user_id() AND deleted_at IS NULL)
  WITH CHECK (id = auth.current_user_id());

-- Only admins can delete users
CREATE POLICY "Admins can delete users"
  ON users FOR DELETE
  USING (auth.is_admin());

-- ═══════════════════════════════════════════════════════════════════════════
-- Borrowers
-- ═══════════════════════════════════════════════════════════════════════════

-- Borrowers can read their own record
CREATE POLICY "Borrowers can read own record"
  ON borrowers FOR SELECT
  USING (
    user_id = auth.current_user_id()
    AND deleted_at IS NULL
  );

-- Managers and admins can read all borrowers
CREATE POLICY "Managers and admins can read all borrowers"
  ON borrowers FOR SELECT
  USING (
    (auth.is_manager() OR auth.is_admin())
    AND deleted_at IS NULL
  );

-- Borrowers can update their own record
CREATE POLICY "Borrowers can update own record"
  ON borrowers FOR UPDATE
  USING (
    user_id = auth.current_user_id()
    AND deleted_at IS NULL
  );

-- Riders can read borrower info for their assigned tasks
CREATE POLICY "Riders can read assigned borrowers"
  ON borrowers FOR SELECT
  USING (
    auth.is_rider()
    AND deleted_at IS NULL
    AND (
      id IN (
        SELECT l.borrower_id FROM loans l
        JOIN disbursements d ON d.loan_id = l.id
        WHERE d.assigned_rider_id IN (
          SELECT r.id FROM riders r WHERE r.user_id = auth.current_user_id()
        )
      )
      OR id IN (
        SELECT c.borrower_id FROM collections c
        WHERE c.assigned_rider_id IN (
          SELECT r.id FROM riders r WHERE r.user_id = auth.current_user_id()
        )
      )
    )
  );

-- ═══════════════════════════════════════════════════════════════════════════
-- Loans
-- ═══════════════════════════════════════════════════════════════════════════

-- Borrowers can read their own loans
CREATE POLICY "Borrowers can read own loans"
  ON loans FOR SELECT
  USING (
    borrower_id IN (
      SELECT b.id FROM borrowers b WHERE b.user_id = auth.current_user_id()
    )
    AND deleted_at IS NULL
  );

-- Managers and admins can read all loans
CREATE POLICY "Managers and admins can read all loans"
  ON loans FOR SELECT
  USING (
    (auth.is_manager() OR auth.is_admin())
    AND deleted_at IS NULL
  );

-- Borrowers can create loans
CREATE POLICY "Borrowers can create loans"
  ON loans FOR INSERT
  WITH CHECK (
    borrower_id IN (
      SELECT b.id FROM borrowers b WHERE b.user_id = auth.current_user_id()
    )
    AND deleted_at IS NULL
  );

-- No mobile role can update/delete loans (managed via edge functions only)
-- Managers/admins can update loans (state transitions done via edge functions with service key)
CREATE POLICY "Managers and admins can update loans"
  ON loans FOR UPDATE
  USING (
    (auth.is_manager() OR auth.is_admin())
    AND deleted_at IS NULL
  );

-- ═══════════════════════════════════════════════════════════════════════════
-- Loan Schedules
-- ═══════════════════════════════════════════════════════════════════════════

-- Borrowers can read own loan schedules
CREATE POLICY "Borrowers can read own loan schedules"
  ON loan_schedules FOR SELECT
  USING (
    loan_id IN (
      SELECT l.id FROM loans l
      JOIN borrowers b ON l.borrower_id = b.id
      WHERE b.user_id = auth.current_user_id()
    )
  );

-- Managers and admins can read all schedules
CREATE POLICY "Managers and admins can read all schedules"
  ON loan_schedules FOR SELECT
  USING (auth.is_manager() OR auth.is_admin());

-- ═══════════════════════════════════════════════════════════════════════════
-- Payments
-- ═══════════════════════════════════════════════════════════════════════════

-- Borrowers can read own payments
CREATE POLICY "Borrowers can read own payments"
  ON payments FOR SELECT
  USING (
    borrower_id IN (
      SELECT b.id FROM borrowers b WHERE b.user_id = auth.current_user_id()
    )
    AND deleted_at IS NULL
  );

-- Managers and admins can read all payments
CREATE POLICY "Managers and admins can read all payments"
  ON payments FOR SELECT
  USING (
    (auth.is_manager() OR auth.is_admin())
    AND deleted_at IS NULL
  );

-- Borrowers can create payments
CREATE POLICY "Borrowers can create payments"
  ON payments FOR INSERT
  WITH CHECK (
    borrower_id IN (
      SELECT b.id FROM borrowers b WHERE b.user_id = auth.current_user_id()
    )
  );

-- ═══════════════════════════════════════════════════════════════════════════
-- Disbursements
-- ═══════════════════════════════════════════════════════════════════════════

-- Borrowers can read own disbursements
CREATE POLICY "Borrowers can read own disbursements"
  ON disbursements FOR SELECT
  USING (
    loan_id IN (
      SELECT l.id FROM loans l
      JOIN borrowers b ON l.borrower_id = b.id
      WHERE b.user_id = auth.current_user_id()
    )
    AND deleted_at IS NULL
  );

-- Riders can read their assigned disbursements
CREATE POLICY "Riders can read assigned disbursements"
  ON disbursements FOR SELECT
  USING (
    assigned_rider_id IN (
      SELECT r.id FROM riders r WHERE r.user_id = auth.current_user_id()
    )
    AND deleted_at IS NULL
  );

-- Managers and admins can read all disbursements
CREATE POLICY "Managers and admins can read all disbursements"
  ON disbursements FOR SELECT
  USING (
    (auth.is_manager() OR auth.is_admin())
    AND deleted_at IS NULL
  );

-- Riders can update their assigned disbursements
CREATE POLICY "Riders can update assigned disbursements"
  ON disbursements FOR UPDATE
  USING (
    assigned_rider_id IN (
      SELECT r.id FROM riders r WHERE r.user_id = auth.current_user_id()
    )
    AND deleted_at IS NULL
  );

-- ═══════════════════════════════════════════════════════════════════════════
-- Collections
-- ═══════════════════════════════════════════════════════════════════════════

-- Borrowers can read own collections
CREATE POLICY "Borrowers can read own collections"
  ON collections FOR SELECT
  USING (
    borrower_id IN (
      SELECT b.id FROM borrowers b WHERE b.user_id = auth.current_user_id()
    )
    AND deleted_at IS NULL
  );

-- Riders can read their assigned collections
CREATE POLICY "Riders can read assigned collections"
  ON collections FOR SELECT
  USING (
    assigned_rider_id IN (
      SELECT r.id FROM riders r WHERE r.user_id = auth.current_user_id()
    )
    AND deleted_at IS NULL
  );

-- Managers and admins can read all collections
CREATE POLICY "Managers and admins can read all collections"
  ON collections FOR SELECT
  USING (
    (auth.is_manager() OR auth.is_admin())
    AND deleted_at IS NULL
  );

-- Riders can update their assigned collections
CREATE POLICY "Riders can update assigned collections"
  ON collections FOR UPDATE
  USING (
    assigned_rider_id IN (
      SELECT r.id FROM riders r WHERE r.user_id = auth.current_user_id()
    )
    AND deleted_at IS NULL
  );

-- ═══════════════════════════════════════════════════════════════════════════
-- Documents
-- ═══════════════════════════════════════════════════════════════════════════

-- Borrowers can read own documents
CREATE POLICY "Borrowers can read own documents"
  ON documents FOR SELECT
  USING (
    borrower_id IN (
      SELECT b.id FROM borrowers b WHERE b.user_id = auth.current_user_id()
    )
    AND deleted_at IS NULL
  );

-- Managers and admins can read all documents
CREATE POLICY "Managers and admins can read all documents"
  ON documents FOR SELECT
  USING (
    (auth.is_manager() OR auth.is_admin())
    AND deleted_at IS NULL
  );

-- Borrowers can create documents
CREATE POLICY "Borrowers can create documents"
  ON documents FOR INSERT
  WITH CHECK (
    borrower_id IN (
      SELECT b.id FROM borrowers b WHERE b.user_id = auth.current_user_id()
    )
  );

-- Managers and admins can update document status (verify/reject)
CREATE POLICY "Managers and admins can update documents"
  ON documents FOR UPDATE
  USING (
    (auth.is_manager() OR auth.is_admin())
    AND deleted_at IS NULL
  );

-- ═══════════════════════════════════════════════════════════════════════════
-- Notifications
-- ═══════════════════════════════════════════════════════════════════════════

-- Users can read their own notifications
CREATE POLICY "Users can read own notifications"
  ON notifications FOR SELECT
  USING (user_id = auth.current_user_id());

-- Users can update their own notifications (mark as read)
CREATE POLICY "Users can update own notifications"
  ON notifications FOR UPDATE
  USING (user_id = auth.current_user_id());

-- ═══════════════════════════════════════════════════════════════════════════
-- OTP Codes — no direct access from client
-- ═══════════════════════════════════════════════════════════════════════════

-- No direct RLS policies — OTP codes are managed only via edge functions
CREATE POLICY "No direct access to OTP codes"
  ON otp_codes FOR ALL
  USING (false)
  WITH CHECK (false);

-- ═══════════════════════════════════════════════════════════════════════════
-- Audit Logs — read-only for admins
-- ═══════════════════════════════════════════════════════════════════════════

CREATE POLICY "Admins can read audit logs"
  ON audit_logs FOR SELECT
  USING (auth.is_admin());

-- ═══════════════════════════════════════════════════════════════════════════
-- Idempotency Keys — no direct client access
-- ═══════════════════════════════════════════════════════════════════════════

CREATE POLICY "No direct access to idempotency keys"
  ON idempotency_keys FOR ALL
  USING (false)
  WITH CHECK (false);

-- ═══════════════════════════════════════════════════════════════════════════
-- System Settings — admins only
-- ═══════════════════════════════════════════════════════════════════════════

CREATE POLICY "Admins can read system settings"
  ON system_settings FOR SELECT
  USING (auth.is_admin());

CREATE POLICY "Admins can update system settings"
  ON system_settings FOR UPDATE
  USING (auth.is_admin());

-- ═══════════════════════════════════════════════════════════════════════════
-- Co-Makers — managed via edge functions
-- ═══════════════════════════════════════════════════════════════════════════

CREATE POLICY "Borrowers can read own co-makers"
  ON co_makers FOR SELECT
  USING (
    id IN (
      SELECT lcm.co_maker_id FROM loan_co_makers lcm
      JOIN loans l ON lcm.loan_id = l.id
      JOIN borrowers b ON l.borrower_id = b.id
      WHERE b.user_id = auth.current_user_id()
    )
  );

CREATE POLICY "Managers and admins can read all co-makers"
  ON co_makers FOR SELECT
  USING (auth.is_manager() OR auth.is_admin());

-- ═══════════════════════════════════════════════════════════════════════════
-- Borrower Phones
-- ═══════════════════════════════════════════════════════════════════════════

CREATE POLICY "Borrowers can read own phones"
  ON borrower_phones FOR SELECT
  USING (
    borrower_id IN (
      SELECT b.id FROM borrowers b WHERE b.user_id = auth.current_user_id()
    )
  );

CREATE POLICY "Managers and admins can read all borrower phones"
  ON borrower_phones FOR SELECT
  USING (auth.is_manager() OR auth.is_admin());

-- ═══════════════════════════════════════════════════════════════════════════
-- Riders
-- ═══════════════════════════════════════════════════════════════════════════

-- Riders can read own record
CREATE POLICY "Riders can read own record"
  ON riders FOR SELECT
  USING (
    user_id = auth.current_user_id()
    AND deleted_at IS NULL
  );

-- Managers and admins can read all riders
CREATE POLICY "Managers and admins can read all riders"
  ON riders FOR SELECT
  USING (
    (auth.is_manager() OR auth.is_admin())
    AND deleted_at IS NULL
  );

-- Riders can update own location/availability
CREATE POLICY "Riders can update own record"
  ON riders FOR UPDATE
  USING (
    user_id = auth.current_user_id()
    AND deleted_at IS NULL
  );

-- ═══════════════════════════════════════════════════════════════════════════
-- Loan Co-Makers Junction
-- ═══════════════════════════════════════════════════════════════════════════

CREATE POLICY "Borrowers can read own loan co-makers"
  ON loan_co_makers FOR SELECT
  USING (
    loan_id IN (
      SELECT l.id FROM loans l
      JOIN borrowers b ON l.borrower_id = b.id
      WHERE b.user_id = auth.current_user_id()
    )
  );

CREATE POLICY "Managers and admins can read all loan co-makers"
  ON loan_co_makers FOR SELECT
  USING (auth.is_manager() OR auth.is_admin());
