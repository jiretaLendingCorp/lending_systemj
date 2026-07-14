-- ============================================================================
-- LendFlow: Additional Audit Log Setup, Indexes, and pg_cron Jobs
-- Migration 0004_audit_log.sql
-- ============================================================================

-- ═══════════════════════════════════════════════════════════════════════════
-- 1. Additional Indexes for Performance
-- ═══════════════════════════════════════════════════════════════════════════

-- Composite indexes for common query patterns
CREATE INDEX idx_loans_borrower_status ON loans(borrower_id, status) WHERE deleted_at IS NULL;
CREATE INDEX idx_loans_status_due ON loans(status, due_at) WHERE deleted_at IS NULL;
CREATE INDEX idx_payments_loan_status ON payments(loan_id, status) WHERE deleted_at IS NULL;
CREATE INDEX idx_payments_borrower_created ON payments(borrower_id, created_at DESC) WHERE deleted_at IS NULL;

-- Partial index for active disbursements
CREATE INDEX idx_disbursements_active ON disbursements(assigned_rider_id, status)
  WHERE status IN ('assigned', 'in_transit') AND deleted_at IS NULL;

-- Partial index for active collections
CREATE INDEX idx_collections_active ON collections(assigned_rider_id, status)
  WHERE status IN ('assigned', 'in_transit') AND deleted_at IS NULL;

-- Audit log composite indexes
CREATE INDEX idx_audit_logs_action_created ON audit_logs(action, created_at DESC);
CREATE INDEX idx_audit_logs_user_action ON audit_logs(user_id, action) WHERE user_id IS NOT NULL;

-- Notification indexes
CREATE INDEX idx_notifications_user_unread ON notifications(user_id, created_at DESC) WHERE is_read = false;

-- ═══════════════════════════════════════════════════════════════════════════
-- 2. Audit Log Helper Functions
-- ═══════════════════════════════════════════════════════════════════════════

-- Function to query audit trail for a specific entity
CREATE OR REPLACE FUNCTION get_entity_audit_trail(
  p_table_name TEXT,
  p_record_id UUID,
  p_limit INTEGER DEFAULT 50
)
RETURNS TABLE (
  id UUID,
  user_id UUID,
  user_role TEXT,
  action TEXT,
  old_value JSONB,
  new_value JSONB,
  created_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    al.id,
    al.user_id,
    al.user_role,
    al.action,
    al.old_value,
    al.new_value,
    al.created_at
  FROM audit_logs al
  WHERE al.action LIKE p_table_name || '_%'
    AND (
      al.old_value->>'id' = p_record_id::TEXT
      OR al.new_value->>'id' = p_record_id::TEXT
    )
  ORDER BY al.created_at DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get recent audit entries for a user
CREATE OR REPLACE FUNCTION get_user_audit_trail(
  p_user_id UUID,
  p_limit INTEGER DEFAULT 50
)
RETURNS TABLE (
  id UUID,
  action TEXT,
  old_value JSONB,
  new_value JSONB,
  created_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    al.id,
    al.action,
    al.old_value,
    al.new_value,
    al.created_at
  FROM audit_logs al
  WHERE al.user_id = p_user_id
  ORDER BY al.created_at DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ═══════════════════════════════════════════════════════════════════════════
-- 3. Materialized View for Dashboard Statistics
-- ═══════════════════════════════════════════════════════════════════════════

CREATE MATERIALIZED VIEW mv_portfolio_summary AS
SELECT
  COUNT(*) FILTER (WHERE l.status = 'draft') AS draft_loans,
  COUNT(*) FILTER (WHERE l.status = 'under_review') AS under_review_loans,
  COUNT(*) FILTER (WHERE l.status = 'approved') AS approved_loans,
  COUNT(*) FILTER (WHERE l.status = 'disbursed') AS disbursed_loans,
  COUNT(*) FILTER (WHERE l.status = 'paid') AS paid_loans,
  COUNT(*) FILTER (WHERE l.status = 'defaulted') AS defaulted_loans,
  COUNT(*) FILTER (WHERE l.status = 'rejected') AS rejected_loans,
  COALESCE(SUM(l.principal) FILTER (WHERE l.status IN ('disbursed', 'defaulted')), 0) AS active_principal,
  COALESCE(SUM(l.total_payable) FILTER (WHERE l.status IN ('disbursed', 'defaulted')), 0) AS active_payable,
  COALESCE(SUM(l.penalty_amount) FILTER (WHERE l.status = 'defaulted'), 0) AS total_penalties,
  (SELECT COUNT(*) FROM borrowers WHERE deleted_at IS NULL) AS total_borrowers,
  (SELECT COUNT(*) FROM riders WHERE deleted_at IS NULL) AS total_riders,
  COALESCE(SUM(p.amount) FILTER (WHERE p.status = 'completed'), 0) AS total_collected
FROM loans l
LEFT JOIN payments p ON p.loan_id = l.id AND p.deleted_at IS NULL
WHERE l.deleted_at IS NULL;

CREATE UNIQUE INDEX idx_mv_portfolio_summary ON mv_portfolio_summary (draft_loans);

-- Refresh function
CREATE OR REPLACE FUNCTION refresh_portfolio_summary()
RETURNS VOID AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY mv_portfolio_summary;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ═══════════════════════════════════════════════════════════════════════════
-- 4. Overdue Loans View
-- ═══════════════════════════════════════════════════════════════════════════

CREATE VIEW v_overdue_loans AS
SELECT
  l.id AS loan_id,
  l.principal,
  l.total_payable,
  l.penalty_amount,
  COALESCE(l.final_balance, l.total_payable + COALESCE(l.penalty_amount, 0)) AS amount_owed,
  l.due_at,
  l.status,
  l.defaulted_at,
  EXTRACT(DAY FROM now() - l.due_at)::INTEGER AS days_overdue,
  b.id AS borrower_id,
  b.full_name AS borrower_name,
  b.phone AS borrower_phone,
  u.email AS borrower_email,
  COALESCE(SUM(p.amount) FILTER (WHERE p.status = 'completed'), 0) AS total_paid,
  COALESCE(l.final_balance, l.total_payable + COALESCE(l.penalty_amount, 0)) - COALESCE(SUM(p.amount) FILTER (WHERE p.status = 'completed'), 0) AS outstanding_balance
FROM loans l
JOIN borrowers b ON l.borrower_id = b.id
JOIN users u ON b.user_id = u.id
LEFT JOIN payments p ON p.loan_id = l.id AND p.deleted_at IS NULL
WHERE l.status IN ('disbursed', 'defaulted')
  AND l.due_at < now()
  AND l.deleted_at IS NULL
  AND b.deleted_at IS NULL
GROUP BY l.id, b.id, u.email;

-- ═══════════════════════════════════════════════════════════════════════════
-- 5. Rider Task Summary View
-- ═══════════════════════════════════════════════════════════════════════════

CREATE VIEW v_rider_tasks AS
SELECT
  'disbursement' AS task_type,
  d.id AS task_id,
  d.status,
  d.created_at,
  r.id AS rider_id,
  r.user_id AS rider_user_id,
  l.principal AS loan_amount,
  l.total_payable,
  b.full_name AS borrower_name,
  b.phone AS borrower_phone,
  b.address AS borrower_address
FROM disbursements d
JOIN riders r ON d.assigned_rider_id = r.id
JOIN loans l ON d.loan_id = l.id
JOIN borrowers b ON l.borrower_id = b.id
WHERE d.deleted_at IS NULL AND r.deleted_at IS NULL

UNION ALL

SELECT
  'collection' AS task_type,
  c.id AS task_id,
  c.status,
  c.created_at,
  r.id AS rider_id,
  r.user_id AS rider_user_id,
  c.amount AS loan_amount,
  c.amount AS total_payable,
  b.full_name AS borrower_name,
  b.phone AS borrower_phone,
  b.address AS borrower_address
FROM collections c
JOIN riders r ON c.assigned_rider_id = r.id
JOIN borrowers b ON c.borrower_id = b.id
WHERE c.deleted_at IS NULL AND r.deleted_at IS NULL;

-- ═══════════════════════════════════════════════════════════════════════════
-- 6. pg_cron Jobs
-- ═══════════════════════════════════════════════════════════════════════════

-- Mark overdue installments daily at 12:05 AM
SELECT extensions.cron_schedule(
  'mark-overdue-installments',
  '5 0 * * *',
  $$SELECT mark_overdue_installments();$$
);

-- Cleanup expired idempotency keys daily at 2:00 AM
SELECT extensions.cron_schedule(
  'cleanup-idempotency-keys',
  '0 2 * * *',
  $$SELECT cleanup_expired_idempotency_keys();$$
);

-- Cleanup expired OTP codes daily at 2:30 AM
SELECT extensions.cron_schedule(
  'cleanup-expired-otps',
  '30 2 * * *',
  $$SELECT cleanup_expired_otps();$$
);

-- Refresh portfolio summary every hour
SELECT extensions.cron_schedule(
  'refresh-portfolio-summary',
  '0 * * * *',
  $$SELECT refresh_portfolio_summary();$$
);

-- Penalty computation: call the edge function daily at 1:00 AM
-- This requires pg_net extension and the cron secret
SELECT extensions.cron_schedule(
  'compute-penalties',
  '0 1 * * *',
  $$
  SELECT net.http_post(
    url := current_setting('app.functions_base_url', true) || '/loans-compute-penalty',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-cron-secret', current_setting('app.cron_secret', true)
    ),
    body := '{}'::jsonb
  );
  $$
);

-- SMS reminders: call the edge function daily at 9:00 AM
SELECT extensions.cron_schedule(
  'send-sms-reminders',
  '0 9 * * *',
  $$
  SELECT net.http_post(
    url := current_setting('app.functions_base_url', true) || '/notifications-send-sms',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-cron-secret', current_setting('app.cron_secret', true)
    ),
    body := '{}'::jsonb
  );
  $$
);

-- ═══════════════════════════════════════════════════════════════════════════
-- 7. Statistics Functions for Reports
-- ═══════════════════════════════════════════════════════════════════════════

-- Get collection efficiency metrics
CREATE OR REPLACE FUNCTION get_collection_efficiency(
  p_start_date DATE DEFAULT CURRENT_DATE - INTERVAL '30 days',
  p_end_date DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE (
  metric TEXT,
  value NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT 'total_due'::TEXT, COALESCE(SUM(l.total_payable), 0)
  FROM loans l
  WHERE l.due_at::DATE BETWEEN p_start_date AND p_end_date
    AND l.status IN ('disbursed', 'defaulted', 'paid')
    AND l.deleted_at IS NULL

  UNION ALL

  SELECT 'total_collected'::TEXT, COALESCE(SUM(p.amount), 0)
  FROM payments p
  WHERE p.created_at::DATE BETWEEN p_start_date AND p_end_date
    AND p.status = 'completed'
    AND p.deleted_at IS NULL

  UNION ALL

  SELECT 'collection_rate'::TEXT,
    CASE
      WHEN COALESCE(SUM(l.total_payable), 0) = 0 THEN 0
      ELSE ROUND((COALESCE(SUM(p.amount), 0) / COALESCE(SUM(l.total_payable), 1)) * 100, 2)
    END
  FROM loans l
  LEFT JOIN payments p ON p.loan_id = l.id AND p.status = 'completed' AND p.deleted_at IS NULL
  WHERE l.due_at::DATE BETWEEN p_start_date AND p_end_date
    AND l.status IN ('disbursed', 'defaulted', 'paid')
    AND l.deleted_at IS NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ═══════════════════════════════════════════════════════════════════════════
-- 8. Grant necessary permissions
-- ═══════════════════════════════════════════════════════════════════════════

-- Allow service role to bypass RLS for edge functions
GRANT ALL ON ALL TABLES IN SCHEMA public TO service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO service_role;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO service_role;

-- Authenticated users can read views
GRANT SELECT ON v_overdue_loans TO authenticated;
GRANT SELECT ON v_rider_tasks TO authenticated;
GRANT SELECT ON mv_portfolio_summary TO authenticated;

-- Allow authenticated users to call utility functions
GRANT EXECUTE ON FUNCTION mark_overdue_installments() TO service_role;
GRANT EXECUTE ON FUNCTION cleanup_expired_idempotency_keys() TO service_role;
GRANT EXECUTE ON FUNCTION cleanup_expired_otps() TO service_role;
GRANT EXECUTE ON FUNCTION refresh_portfolio_summary() TO service_role;
GRANT EXECUTE ON FUNCTION approve_loan(UUID, UUID, TIMESTAMPTZ) TO service_role;
GRANT EXECUTE ON FUNCTION get_entity_audit_trail(TEXT, UUID, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_audit_trail(UUID, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_collection_efficiency(DATE, DATE) TO authenticated;
