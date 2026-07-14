-- ============================================================================
-- LendFlow: Triggers, Stored Procedures, and Business Logic
-- Migration 0003_triggers.sql
-- ============================================================================

-- ═══════════════════════════════════════════════════════════════════════════
-- 1. Audit Log Trigger — captures old/new values on UPDATE
-- ═══════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION trg_audit_log_fn()
RETURNS TRIGGER AS $$
DECLARE
  v_user_id UUID;
  v_user_role TEXT;
  v_ip_address INET;
BEGIN
  -- Get current user info from JWT if available
  v_user_id := auth.uid();
  v_user_role := (auth.jwt() -> 'app_metadata' ->> 'role')::TEXT;
  v_ip_address := NULL; -- IP captured in edge functions

  INSERT INTO audit_logs (user_id, user_role, action, old_value, new_value, ip_address)
  VALUES (
    v_user_id,
    v_user_role,
    TG_TABLE_NAME || '_' || TG_OP,
    CASE WHEN TG_OP = 'DELETE' THEN to_jsonb(OLD) ELSE to_jsonb(OLD) END,
    CASE WHEN TG_OP = 'INSERT' THEN to_jsonb(NEW)
         WHEN TG_OP = 'UPDATE' THEN to_jsonb(NEW)
         ELSE NULL END,
    v_ip_address
  );

  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Apply audit log trigger to critical tables
CREATE TRIGGER trg_audit_loans
  AFTER INSERT OR UPDATE OR DELETE ON loans
  FOR EACH ROW EXECUTE FUNCTION trg_audit_log_fn();

CREATE TRIGGER trg_audit_payments
  AFTER INSERT OR UPDATE OR DELETE ON payments
  FOR EACH ROW EXECUTE FUNCTION trg_audit_log_fn();

CREATE TRIGGER trg_audit_disbursements
  AFTER INSERT OR UPDATE OR DELETE ON disbursements
  FOR EACH ROW EXECUTE FUNCTION trg_audit_log_fn();

CREATE TRIGGER trg_audit_collections
  AFTER INSERT OR UPDATE OR DELETE ON collections
  FOR EACH ROW EXECUTE FUNCTION trg_audit_log_fn();

-- ═══════════════════════════════════════════════════════════════════════════
-- 2. Loan Status Guard — rejects illegal state transitions
-- ═══════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION trg_loan_status_guard_fn()
RETURNS TRIGGER AS $$
DECLARE
  allowed_transitions JSONB;
  allowed_next TEXT[];
BEGIN
  -- Define legal transitions
  allowed_transitions := '{
    "draft": ["under_review"],
    "under_review": ["approved", "rejected"],
    "approved": ["disbursed", "rejected"],
    "disbursed": ["paid", "defaulted"],
    "paid": [],
    "defaulted": ["paid"],
    "rejected": ["draft"]
  }'::jsonb;

  -- Only check when status is being changed
  IF OLD.status IS DISTINCT FROM NEW.status THEN
    allowed_next := ARRAY(SELECT jsonb_array_elements_text(allowed_transions -> OLD.status));

    IF NOT NEW.status = ANY(allowed_next) THEN
      RAISE EXCEPTION 'Invalid loan status transition: % -> %. Allowed: %',
        OLD.status, NEW.status, array_to_string(allowed_next, ', ');
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_loan_status_guard
  BEFORE UPDATE ON loans
  FOR EACH ROW EXECUTE FUNCTION trg_loan_status_guard_fn();

-- ═══════════════════════════════════════════════════════════════════════════
-- 3. Auto-Generate Schedule — on loan approval
-- ═══════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION trg_auto_generate_schedule_fn()
RETURNS TRIGGER AS $$
DECLARE
  v_installment_count INTEGER;
  v_amount_per_installment NUMERIC(12, 2);
  v_due_date DATE;
  v_interval_days INTEGER;
  v_total_payable NUMERIC(12, 2);
BEGIN
  -- Only generate schedule when status transitions TO approved
  IF OLD.status IS DISTINCT FROM NEW.status AND NEW.status = 'approved' THEN
    v_total_payable := NEW.total_payable;

    -- Calculate number of installments and interval based on schedule type
    CASE NEW.schedule_type
      WHEN 'daily' THEN
        v_installment_count := NEW.term_days;
        v_interval_days := 1;
      WHEN 'weekly' THEN
        v_installment_count := GREATEST(1, FLOOR(NEW.term_days / 7.0)::INTEGER);
        v_interval_days := 7;
      WHEN 'monthly' THEN
        v_installment_count := GREATEST(1, FLOOR(NEW.term_days / 30.0)::INTEGER);
        v_interval_days := 30;
    END CASE;

    v_amount_per_installment := ROUND(v_total_payable / v_installment_count, 2);
    v_due_date := CURRENT_DATE;

    -- Generate installments
    FOR i IN 1..v_installment_count LOOP
      v_due_date := v_due_date + v_interval_days;

      INSERT INTO loan_schedules (loan_id, installment_number, amount_due, due_date, status)
      VALUES (
        NEW.id,
        i,
        -- Last installment gets the remainder to avoid rounding issues
        CASE
          WHEN i = v_installment_count THEN v_total_payable - (v_amount_per_installment * (i - 1))
          ELSE v_amount_per_installment
        END,
        v_due_date,
        'pending'
      );
    END LOOP;

    -- Update loan due_at with the last installment date
    UPDATE loans
    SET due_at = (v_due_date + INTERVAL '1 day')::timestamptz
    WHERE id = NEW.id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_auto_generate_schedule
  AFTER UPDATE ON loans
  FOR EACH ROW EXECUTE FUNCTION trg_auto_generate_schedule_fn();

-- ═══════════════════════════════════════════════════════════════════════════
-- 4. approve_loan Stored Procedure — atomic state transition with RLS bypass
-- ═══════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION approve_loan(
  p_loan_id UUID,
  p_approved_by UUID,
  p_approved_at TIMESTAMPTZ
)
RETURNS JSONB AS $$
DECLARE
  v_current_status loan_status;
  v_result JSONB;
BEGIN
  -- Get current status with row lock
  SELECT status INTO v_current_status
  FROM loans
  WHERE id = p_loan_id AND deleted_at IS NULL
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('error', 'Loan not found');
  END IF;

  IF v_current_status != 'under_review' THEN
    RETURN jsonb_build_object(
      'error', 'Invalid status transition',
      'current_status', v_current_status,
      'expected_status', 'under_review'
    );
  END IF;

  -- Perform the update
  UPDATE loans
  SET
    status = 'approved',
    approved_by = p_approved_by,
    approved_at = p_approved_at,
    updated_at = now()
  WHERE id = p_loan_id AND status = 'under_review';

  -- Log the approval
  INSERT INTO audit_logs (user_id, user_role, action, old_value, new_value)
  VALUES (
    p_approved_by,
    'system_procedure',
    'loan_approved_procedure',
    jsonb_build_object('status', v_current_status),
    jsonb_build_object('status', 'approved', 'approved_by', p_approved_by)
  );

  RETURN jsonb_build_object(
    'success', true,
    'loan_id', p_loan_id,
    'status', 'approved'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ═══════════════════════════════════════════════════════════════════════════
-- 5. Update Loan on Payment — marks loan as paid when all installments settled
-- ═══════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION trg_update_loan_on_payment_fn()
RETURNS TRIGGER AS $$
DECLARE
  v_loan_id UUID;
  v_total_payable NUMERIC(12, 2);
  v_total_paid NUMERIC(12, 2);
  v_penalty_amount NUMERIC(12, 2);
  v_final_balance NUMERIC(12, 2);
BEGIN
  -- Only act on completed payments
  IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN
    v_loan_id := NEW.loan_id;

    -- Get loan details
    SELECT total_payable, penalty_amount, final_balance
    INTO v_total_payable, v_penalty_amount, v_final_balance
    FROM loans WHERE id = v_loan_id;

    -- Calculate total paid
    SELECT COALESCE(SUM(amount), 0)
    INTO v_total_paid
    FROM payments
    WHERE loan_id = v_loan_id AND status = 'completed' AND deleted_at IS NULL;

    -- Check if fully paid
    IF v_total_paid >= COALESCE(v_final_balance, v_total_payable + COALESCE(v_penalty_amount, 0)) THEN
      -- Mark all remaining installments as paid
      UPDATE loan_schedules
      SET status = 'paid', paid_at = now()
      WHERE loan_id = v_loan_id AND status = 'pending';

      -- Mark loan as paid (bypass trigger by using direct update)
      UPDATE loans
      SET status = 'paid', updated_at = now()
      WHERE id = v_loan_id AND status IN ('disbursed', 'defaulted');
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_update_loan_on_payment
  AFTER UPDATE ON payments
  FOR EACH ROW EXECUTE FUNCTION trg_update_loan_on_payment_fn();

-- ═══════════════════════════════════════════════════════════════════════════
-- 6. Mark overdue installments
-- ═══════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION mark_overdue_installments()
RETURNS VOID AS $$
BEGIN
  UPDATE loan_schedules
  SET status = 'overdue'
  WHERE status = 'pending'
    AND due_date < CURRENT_DATE
    AND loan_id IN (SELECT id FROM loans WHERE status IN ('disbursed', 'defaulted'));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ═══════════════════════════════════════════════════════════════════════════
-- 7. Compute loan due date on disbursement
-- ═══════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION trg_set_loan_due_at_fn()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.status IS DISTINCT FROM NEW.status AND NEW.status = 'disbursed' THEN
    IF NEW.due_at IS NULL THEN
      -- Set due_at based on the last installment date
      SELECT MAX(due_date + INTERVAL '1 day')
      INTO NEW.due_at
      FROM loan_schedules
      WHERE loan_id = NEW.id;

      IF NEW.due_at IS NULL THEN
        -- Fallback: use term_days from now
        NEW.due_at := now() + (NEW.term_days || ' days')::INTERVAL;
      END IF;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_set_loan_due_at
  BEFORE UPDATE ON loans
  FOR EACH ROW EXECUTE FUNCTION trg_set_loan_due_at_fn();

-- ═══════════════════════════════════════════════════════════════════════════
-- 8. Cleanup expired idempotency keys
-- ═══════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION cleanup_expired_idempotency_keys()
RETURNS VOID AS $$
BEGIN
  DELETE FROM idempotency_keys WHERE expires_at < now();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ═══════════════════════════════════════════════════════════════════════════
-- 9. Cleanup expired OTP codes
-- ═══════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION cleanup_expired_otps()
RETURNS VOID AS $$
BEGIN
  DELETE FROM otp_codes WHERE expires_at < now() OR (is_used = true AND created_at < now() - INTERVAL '24 hours');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
