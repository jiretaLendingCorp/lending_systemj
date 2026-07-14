-- supabase/migrations/0003_triggers.sql
CREATE OR REPLACE FUNCTION public.trg_audit_log_fn()
RETURNS TRIGGER AS $$
DECLARE
  v_user_id UUID;
  v_user_role TEXT;
BEGIN
  v_user_id := auth.uid();
  v_user_role := (auth.jwt() -> 'app_metadata' ->> 'role')::TEXT;

  INSERT INTO audit_logs (user_id, user_role, action, entity_type, entity_id, old_value, new_value)
  VALUES (
    v_user_id,
    v_user_role,
    TG_TABLE_NAME || '_' || TG_OP,
    TG_TABLE_NAME,
    COALESCE(NEW.id, OLD.id),
    CASE WHEN TG_OP IN ('UPDATE','DELETE') THEN to_jsonb(OLD) ELSE NULL END,
    CASE WHEN TG_OP IN ('INSERT','UPDATE') THEN to_jsonb(NEW) ELSE NULL END
  );

  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_audit_loans
  AFTER INSERT OR UPDATE OR DELETE ON loans
  FOR EACH ROW EXECUTE FUNCTION public.trg_audit_log_fn();

CREATE TRIGGER trg_audit_payments
  AFTER INSERT OR UPDATE OR DELETE ON payments
  FOR EACH ROW EXECUTE FUNCTION public.trg_audit_log_fn();

CREATE TRIGGER trg_audit_disbursements
  AFTER INSERT OR UPDATE OR DELETE ON disbursements
  FOR EACH ROW EXECUTE FUNCTION public.trg_audit_log_fn();

CREATE TRIGGER trg_audit_collections
  AFTER INSERT OR UPDATE OR DELETE ON collections
  FOR EACH ROW EXECUTE FUNCTION public.trg_audit_log_fn();

CREATE TRIGGER trg_audit_documents
  AFTER INSERT OR UPDATE OR DELETE ON documents
  FOR EACH ROW EXECUTE FUNCTION public.trg_audit_log_fn();

CREATE OR REPLACE FUNCTION public.trg_loan_status_guard_fn()
RETURNS TRIGGER AS $$
DECLARE
  allowed_transitions JSONB;
  allowed_next TEXT[];
BEGIN
  allowed_transitions := '{
    "draft": ["under_review"],
    "under_review": ["approved", "rejected"],
    "approved": ["disbursed", "rejected"],
    "disbursed": ["paid", "defaulted"],
    "paid": [],
    "defaulted": ["paid"],
    "rejected": ["draft"]
  }'::jsonb;

  IF OLD.status IS DISTINCT FROM NEW.status THEN
    allowed_next := ARRAY(SELECT jsonb_array_elements_text(allowed_transitions -> OLD.status));

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
  FOR EACH ROW EXECUTE FUNCTION public.trg_loan_status_guard_fn();

CREATE OR REPLACE FUNCTION public.trg_auto_generate_schedule_fn()
RETURNS TRIGGER AS $$
DECLARE
  v_installment_count INTEGER;
  v_amount_per_installment NUMERIC(12, 2);
  v_due_date DATE;
  v_interval_days INTEGER;
  v_total_payable NUMERIC(12, 2);
BEGIN
  IF OLD.status IS DISTINCT FROM NEW.status AND NEW.status = 'approved' THEN
    v_total_payable := NEW.total_payable;

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

    FOR i IN 1..v_installment_count LOOP
      v_due_date := v_due_date + v_interval_days;

      INSERT INTO loan_schedules (loan_id, installment_number, amount_due, due_date, status)
      VALUES (
        NEW.id,
        i,
        CASE
          WHEN i = v_installment_count THEN v_total_payable - (v_amount_per_installment * (i - 1))
          ELSE v_amount_per_installment
        END,
        v_due_date,
        'pending'
      );
    END LOOP;

    UPDATE loans
    SET due_at = (v_due_date + INTERVAL '1 day')::timestamptz
    WHERE id = NEW.id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_auto_generate_schedule
  AFTER UPDATE ON loans
  FOR EACH ROW EXECUTE FUNCTION public.trg_auto_generate_schedule_fn();

CREATE OR REPLACE FUNCTION public.approve_loan(
  p_loan_id UUID,
  p_approved_by UUID,
  p_approved_at TIMESTAMPTZ
)
RETURNS JSONB AS $$
DECLARE
  v_current_status loan_status;
BEGIN
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

  UPDATE loans
  SET
    status = 'approved',
    approved_by = p_approved_by,
    approved_at = p_approved_at,
    updated_at = now()
  WHERE id = p_loan_id AND status = 'under_review';

  INSERT INTO audit_logs (user_id, user_role, action, entity_type, entity_id, old_value, new_value)
  VALUES (
    p_approved_by,
    'system_procedure',
    'loan_approved_procedure',
    'loans',
    p_loan_id,
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

CREATE OR REPLACE FUNCTION public.trg_update_loan_on_payment_fn()
RETURNS TRIGGER AS $$
DECLARE
  v_loan_id UUID;
  v_total_payable NUMERIC(12, 2);
  v_total_paid NUMERIC(12, 2);
  v_penalty_amount NUMERIC(12, 2);
  v_final_balance NUMERIC(12, 2);
BEGIN
  IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN
    v_loan_id := NEW.loan_id;

    SELECT total_payable, penalty_amount, final_balance
    INTO v_total_payable, v_penalty_amount, v_final_balance
    FROM loans WHERE id = v_loan_id;

    SELECT COALESCE(SUM(amount), 0)
    INTO v_total_paid
    FROM payments
    WHERE loan_id = v_loan_id AND status = 'completed' AND deleted_at IS NULL;

    IF v_total_paid >= COALESCE(v_final_balance, v_total_payable + COALESCE(v_penalty_amount, 0)) THEN
      UPDATE loan_schedules
      SET status = 'paid', paid_at = now()
      WHERE loan_id = v_loan_id AND status = 'pending';

      UPDATE loans
      SET status = 'paid', updated_at = now(), final_balance = 0
      WHERE id = v_loan_id AND status IN ('disbursed', 'defaulted');
    ELSE
      UPDATE loans
      SET final_balance = COALESCE(v_final_balance, v_total_payable + COALESCE(v_penalty_amount, 0)) - v_total_paid
      WHERE id = v_loan_id;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_update_loan_on_payment
  AFTER UPDATE ON payments
  FOR EACH ROW EXECUTE FUNCTION public.trg_update_loan_on_payment_fn();

CREATE OR REPLACE FUNCTION public.mark_overdue_installments()
RETURNS VOID AS $$
BEGIN
  UPDATE loan_schedules
  SET status = 'overdue'
  WHERE status = 'pending'
    AND due_date < CURRENT_DATE
    AND loan_id IN (SELECT id FROM loans WHERE status IN ('disbursed', 'defaulted'));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.trg_set_loan_due_at_fn()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.status IS DISTINCT FROM NEW.status AND NEW.status = 'disbursed' THEN
    IF NEW.due_at IS NULL THEN
      SELECT MAX(due_date + INTERVAL '1 day')
      INTO NEW.due_at
      FROM loan_schedules
      WHERE loan_id = NEW.id;

      IF NEW.due_at IS NULL THEN
        NEW.due_at := now() + (NEW.term_days || ' days')::INTERVAL;
      END IF;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_set_loan_due_at
  BEFORE UPDATE ON loans
  FOR EACH ROW EXECUTE FUNCTION public.trg_set_loan_due_at_fn();

CREATE OR REPLACE FUNCTION public.cleanup_expired_idempotency_keys()
RETURNS VOID AS $$
BEGIN
  DELETE FROM idempotency_keys WHERE expires_at < now();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.cleanup_expired_otps()
RETURNS VOID AS $$
BEGIN
  DELETE FROM otp_codes WHERE expires_at < now() OR (is_used = true AND created_at < now() - INTERVAL '24 hours');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.compute_penalty_for_loan(p_loan_id UUID)
RETURNS NUMERIC AS $$
DECLARE
  v_penalty_rate NUMERIC(5,4);
  v_threshold_days INTEGER;
  v_principal NUMERIC(12,2);
  v_days_overdue INTEGER;
  v_penalty NUMERIC(12,2);
BEGIN
  SELECT penalty_rate, penalty_threshold_days INTO v_penalty_rate, v_threshold_days
  FROM system_settings ORDER BY updated_at DESC LIMIT 1;

  SELECT principal INTO v_principal FROM loans WHERE id = p_loan_id;

  SELECT GREATEST(0, EXTRACT(DAY FROM now() - due_at)::INTEGER - v_threshold_days)
  INTO v_days_overdue
  FROM loans WHERE id = p_loan_id;

  v_penalty := ROUND((v_principal * v_penalty_rate * v_days_overdue) / 30.0, 2);

  RETURN v_penalty;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
