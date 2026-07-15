-- supabase/migrations/0007_security_invoker_views.sql

DROP VIEW IF EXISTS public.v_overdue_loans;
DROP VIEW IF EXISTS public.v_rider_tasks;

CREATE VIEW public.v_overdue_loans
WITH (security_invoker = true) AS
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
  b.id AS lender_id,
  u.full_name AS lender_name,
  u.phone AS lender_phone,
  u.email AS lender_email,
  COALESCE(SUM(p.amount) FILTER (WHERE p.status = 'completed'), 0) AS total_paid,
  COALESCE(l.final_balance, l.total_payable + COALESCE(l.penalty_amount, 0))
    - COALESCE(SUM(p.amount) FILTER (WHERE p.status = 'completed'), 0) AS outstanding_balance
FROM loans l
JOIN lenders b ON l.lender_id = b.id
JOIN users u ON b.user_id = u.id
LEFT JOIN payments p ON p.loan_id = l.id AND p.deleted_at IS NULL
WHERE l.status IN ('disbursed', 'defaulted')
  AND l.due_at < now()
  AND l.deleted_at IS NULL
  AND b.deleted_at IS NULL
GROUP BY l.id, b.id, u.email, u.full_name, u.phone;

CREATE VIEW public.v_rider_tasks
WITH (security_invoker = true) AS
SELECT
  'disbursement' AS task_type,
  d.id AS task_id,
  d.status::TEXT AS status,
  d.created_at,
  r.id AS rider_id,
  r.user_id AS rider_user_id,
  l.principal AS loan_amount,
  l.total_payable,
  u.full_name AS lender_name,
  u.phone AS lender_phone,
  b.address AS lender_address
FROM disbursements d
JOIN riders r ON d.assigned_rider_id = r.id
JOIN loans l ON d.loan_id = l.id
JOIN lenders b ON l.lender_id = b.id
JOIN users u ON b.user_id = u.id
WHERE d.deleted_at IS NULL AND r.deleted_at IS NULL

UNION ALL

SELECT
  'collection' AS task_type,
  c.id AS task_id,
  c.status::TEXT AS status,
  c.created_at,
  r.id AS rider_id,
  r.user_id AS rider_user_id,
  c.amount AS loan_amount,
  c.amount AS total_payable,
  u.full_name AS lender_name,
  u.phone AS lender_phone,
  b.address AS lender_address
FROM collections c
JOIN riders r ON c.assigned_rider_id = r.id
JOIN lenders b ON c.lender_id = b.id
JOIN users u ON b.user_id = u.id
WHERE c.deleted_at IS NULL AND r.deleted_at IS NULL;

ALTER VIEW public.v_overdue_loans OWNER TO postgres;
ALTER VIEW public.v_rider_tasks   OWNER TO postgres;

GRANT SELECT ON public.v_overdue_loans TO authenticated;
GRANT SELECT ON public.v_rider_tasks   TO authenticated;
