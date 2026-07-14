-- supabase/migrations/0005_realtime.sql
ALTER PUBLICATION supabase_realtime ADD TABLE public.loans;
ALTER PUBLICATION supabase_realtime ADD TABLE public.loan_schedules;
ALTER PUBLICATION supabase_realtime ADD TABLE public.payments;
ALTER PUBLICATION supabase_realtime ADD TABLE public.disbursements;
ALTER PUBLICATION supabase_realtime ADD TABLE public.collections;
ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
ALTER PUBLICATION supabase_realtime ADD TABLE public.documents;
ALTER PUBLICATION supabase_realtime ADD TABLE public.audit_logs;
ALTER PUBLICATION supabase_realtime ADD TABLE public.riders;

ALTER TABLE public.loans REPLICA IDENTITY FULL;
ALTER TABLE public.loan_schedules REPLICA IDENTITY FULL;
ALTER TABLE public.payments REPLICA IDENTITY FULL;
ALTER TABLE public.disbursements REPLICA IDENTITY FULL;
ALTER TABLE public.collections REPLICA IDENTITY FULL;
ALTER TABLE public.notifications REPLICA IDENTITY FULL;
ALTER TABLE public.documents REPLICA IDENTITY FULL;

CREATE OR REPLACE FUNCTION public.notify_role_channel()
RETURNS TRIGGER AS $$
DECLARE
  v_payload JSONB;
  v_target_role TEXT;
BEGIN
  v_payload := jsonb_build_object(
    'table', TG_TABLE_NAME,
    'op', TG_OP,
    'record', CASE WHEN TG_OP IN ('INSERT','UPDATE') THEN to_jsonb(NEW) ELSE to_jsonb(OLD) END,
    'timestamp', now()
  );

  PERFORM pg_notify('realtime:public.' || TG_TABLE_NAME, v_payload::TEXT);

  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_realtime_loans ON public.loans;
CREATE TRIGGER trg_realtime_loans
  AFTER INSERT OR UPDATE OR DELETE ON public.loans
  FOR EACH ROW EXECUTE FUNCTION public.notify_role_channel();

DROP TRIGGER IF EXISTS trg_realtime_payments ON public.payments;
CREATE TRIGGER trg_realtime_payments
  AFTER INSERT OR UPDATE OR DELETE ON public.payments
  FOR EACH ROW EXECUTE FUNCTION public.notify_role_channel();

DROP TRIGGER IF EXISTS trg_realtime_notifications ON public.notifications;
CREATE TRIGGER trg_realtime_notifications
  AFTER INSERT OR UPDATE OR DELETE ON public.notifications
  FOR EACH ROW EXECUTE FUNCTION public.notify_role_channel();

DROP TRIGGER IF EXISTS trg_realtime_disbursements ON public.disbursements;
CREATE TRIGGER trg_realtime_disbursements
  AFTER INSERT OR UPDATE OR DELETE ON public.disbursements
  FOR EACH ROW EXECUTE FUNCTION public.notify_role_channel();

DROP TRIGGER IF EXISTS trg_realtime_collections ON public.collections;
CREATE TRIGGER trg_realtime_collections
  AFTER INSERT OR UPDATE OR DELETE ON public.collections
  FOR EACH ROW EXECUTE FUNCTION public.notify_role_channel();
