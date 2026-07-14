-- supabase/migrations/0006_3nf_integrity.sql
CREATE OR REPLACE FUNCTION public.recompute_final_balance(p_loan_id UUID)
RETURNS VOID AS $$
DECLARE
  v_total_payable NUMERIC(12, 2);
  v_penalty_amount NUMERIC(12, 2);
  v_total_paid NUMERIC(12, 2);
  v_new_final NUMERIC(12, 2);
  v_current_status TEXT;
BEGIN
  SELECT total_payable, COALESCE(penalty_amount, 0), status
    INTO v_total_payable, v_penalty_amount, v_current_status
  FROM loans
  WHERE id = p_loan_id
    AND deleted_at IS NULL;

  IF NOT FOUND THEN
    RETURN;
  END IF;

  SELECT COALESCE(SUM(amount), 0)
    INTO v_total_paid
  FROM payments
  WHERE loan_id = p_loan_id
    AND status = 'completed'
    AND deleted_at IS NULL;

  v_new_final := GREATEST(0, v_total_payable + v_penalty_amount - v_total_paid);

  UPDATE loans
    SET final_balance = v_new_final,
        status = CASE
          WHEN v_new_final = 0 AND v_current_status IN ('disbursed', 'defaulted') THEN 'paid'
          ELSE v_current_status
        END,
        updated_at = now()
  WHERE id = p_loan_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.recompute_final_balance_for_payment()
RETURNS TRIGGER AS $$
DECLARE
  v_loan_id UUID;
BEGIN
  v_loan_id := COALESCE(NEW.loan_id, OLD.loan_id);
  IF v_loan_id IS NOT NULL THEN
    PERFORM public.recompute_final_balance(v_loan_id);
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER trg_payments_recompute_balance
  AFTER INSERT OR UPDATE OR DELETE ON payments
  FOR EACH ROW EXECUTE FUNCTION public.recompute_final_balance_for_payment();

CREATE OR REPLACE FUNCTION public.recompute_final_balance_on_penalty()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM public.recompute_final_balance(NEW.id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER trg_loans_recompute_on_penalty
  AFTER UPDATE OF penalty_amount ON loans
  FOR EACH ROW
  WHEN (OLD.penalty_amount IS DISTINCT FROM NEW.penalty_amount)
  EXECUTE FUNCTION public.recompute_final_balance_on_penalty();

CREATE OR REPLACE FUNCTION public.assert_payment_lender_matches_loan()
RETURNS TRIGGER AS $$
DECLARE
  v_expected_lender UUID;
BEGIN
  SELECT lender_id INTO v_expected_lender
  FROM loans
  WHERE id = NEW.loan_id;

  IF v_expected_lender IS NULL THEN
    RAISE EXCEPTION 'Loan % does not exist', NEW.loan_id
      USING ERRCODE = 'foreign_key_violation';
  END IF;

  IF NEW.lender_id <> v_expected_lender THEN
    RAISE EXCEPTION 'Payment lender_id (%) does not match loan.lender_id (%)',
      NEW.lender_id, v_expected_lender
      USING ERRCODE = 'check_violation';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_payments_lender_integrity ON payments;
CREATE TRIGGER trg_payments_lender_integrity
  BEFORE INSERT OR UPDATE OF lender_id, loan_id ON payments
  FOR EACH ROW EXECUTE FUNCTION public.assert_payment_lender_matches_loan();

CREATE OR REPLACE FUNCTION public.assert_collection_lender_matches_loan()
RETURNS TRIGGER AS $$
DECLARE
  v_expected_lender UUID;
BEGIN
  SELECT lender_id INTO v_expected_lender
  FROM loans
  WHERE id = NEW.loan_id;

  IF v_expected_lender IS NULL THEN
    RAISE EXCEPTION 'Loan % does not exist', NEW.loan_id
      USING ERRCODE = 'foreign_key_violation';
  END IF;

  IF NEW.lender_id <> v_expected_lender THEN
    RAISE EXCEPTION 'Collection lender_id (%) does not match loan.lender_id (%)',
      NEW.lender_id, v_expected_lender
      USING ERRCODE = 'check_violation';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_collections_lender_integrity ON collections;
CREATE TRIGGER trg_collections_lender_integrity
  BEFORE INSERT OR UPDATE OF lender_id, loan_id ON collections
  FOR EACH ROW EXECUTE FUNCTION public.assert_collection_lender_matches_loan();

CREATE OR REPLACE FUNCTION public.sync_primary_co_maker()
RETURNS TRIGGER AS $$
DECLARE
  v_primary_co_maker UUID;
BEGIN
  IF TG_OP = 'DELETE' THEN
    UPDATE loans SET co_maker_id = NULL WHERE id = OLD.loan_id;
    RETURN OLD;
  END IF;

  SELECT co_maker_id INTO v_primary_co_maker
  FROM loan_co_makers
  WHERE loan_id = NEW.loan_id
  ORDER BY id ASC
  LIMIT 1;

  UPDATE loans SET co_maker_id = v_primary_co_maker WHERE id = NEW.loan_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_loan_co_makers_sync ON loan_co_makers;
CREATE TRIGGER trg_loan_co_makers_sync
  AFTER INSERT OR UPDATE OR DELETE ON loan_co_makers
  FOR EACH ROW EXECUTE FUNCTION public.sync_primary_co_maker();

GRANT EXECUTE ON FUNCTION public.recompute_final_balance(UUID) TO service_role;
GRANT EXECUTE ON FUNCTION public.recompute_final_balance_for_payment() TO service_role;
GRANT EXECUTE ON FUNCTION public.recompute_final_balance_on_penalty() TO service_role;
GRANT EXECUTE ON FUNCTION public.assert_payment_lender_matches_loan() TO service_role;
GRANT EXECUTE ON FUNCTION public.assert_collection_lender_matches_loan() TO service_role;
GRANT EXECUTE ON FUNCTION public.sync_primary_co_maker() TO service_role;
