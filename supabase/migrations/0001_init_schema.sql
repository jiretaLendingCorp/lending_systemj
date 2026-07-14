-- supabase/migrations/0001_init_schema.sql
CREATE TYPE user_role AS ENUM ('lender', 'rider', 'employee', 'head_manager');

CREATE TYPE kyc_status AS ENUM (
  'pending',
  'phone_verified',
  'docs_uploaded',
  'verified',
  'rejected'
);

CREATE TYPE loan_status AS ENUM (
  'draft',
  'under_review',
  'approved',
  'disbursed',
  'paid',
  'defaulted',
  'rejected'
);

CREATE TYPE schedule_type AS ENUM ('daily', 'weekly', 'monthly');

CREATE TYPE installment_status AS ENUM ('pending', 'paid', 'overdue');

CREATE TYPE payment_method AS ENUM ('gcash', 'office', 'cash');

CREATE TYPE payment_status AS ENUM ('pending', 'completed', 'failed', 'refunded');

CREATE TYPE disbursement_status AS ENUM (
  'pending',
  'assigned',
  'in_transit',
  'delivered',
  'failed'
);

CREATE TYPE collection_status AS ENUM (
  'pending',
  'assigned',
  'in_transit',
  'collected',
  'failed'
);

CREATE TYPE document_type AS ENUM (
  'government_id',
  'proof_of_billing',
  'selfie',
  'proof_of_income'
);

CREATE TYPE document_status AS ENUM ('pending', 'verified', 'rejected');

CREATE TYPE notification_type AS ENUM (
  'loan_created',
  'loan_approved',
  'loan_rejected',
  'loan_disbursed',
  'loan_defaulted',
  'payment_received',
  'payment_confirmed',
  'payment_collected',
  'payment_reminder',
  'disbursement_assigned',
  'collection_assigned',
  'otp_verified',
  'sms_delivery_failed',
  'email_verification',
  'password_reset'
);

CREATE TYPE disbursement_method AS ENUM ('gcash', 'office', 'cash');

CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pg_net" SCHEMA "extensions";
CREATE EXTENSION IF NOT EXISTS "pg_cron" SCHEMA "extensions";

CREATE TABLE users (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid() REFERENCES auth.users(id) ON DELETE CASCADE,
  email       TEXT NOT NULL UNIQUE,
  phone       TEXT,
  full_name   TEXT NOT NULL,
  role        user_role NOT NULL DEFAULT 'lender',
  is_active   BOOLEAN NOT NULL DEFAULT true,
  last_login_at TIMESTAMPTZ,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at  TIMESTAMPTZ
);

CREATE INDEX idx_users_email ON users(email) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_role ON users(role) WHERE deleted_at IS NULL;

CREATE TABLE lenders (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  address         TEXT,
  birthday        DATE,
  employment_type TEXT,
  monthly_income  NUMERIC(12, 2),
  kyc_status      kyc_status NOT NULL DEFAULT 'pending',
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at      TIMESTAMPTZ
);

CREATE INDEX idx_lenders_user_id ON lenders(user_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_lenders_kyc_status ON lenders(kyc_status) WHERE deleted_at IS NULL;

CREATE TABLE co_makers (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  full_name     TEXT NOT NULL,
  phone         TEXT NOT NULL,
  address       TEXT NOT NULL,
  relationship  TEXT NOT NULL,
  consent_at    TIMESTAMPTZ,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE lender_phones (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lender_id     UUID NOT NULL REFERENCES lenders(id) ON DELETE CASCADE,
  phone_number  TEXT NOT NULL,
  is_primary    BOOLEAN NOT NULL DEFAULT false,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_lender_phones_lender_id ON lender_phones(lender_id);

CREATE TABLE riders (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  is_available      BOOLEAN NOT NULL DEFAULT true,
  current_latitude  DOUBLE PRECISION,
  current_longitude DOUBLE PRECISION,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at        TIMESTAMPTZ
);

CREATE INDEX idx_riders_user_id ON riders(user_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_riders_available ON riders(is_available) WHERE deleted_at IS NULL;

CREATE TABLE loans (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lender_id        UUID NOT NULL REFERENCES lenders(id) ON DELETE RESTRICT,
  co_maker_id      UUID REFERENCES co_makers(id) ON DELETE SET NULL,
  principal        NUMERIC(12, 2) NOT NULL CHECK (principal >= 3000 AND principal <= 500000),
  interest_rate    NUMERIC(5, 4) NOT NULL DEFAULT 0.2000 CHECK (interest_rate = 0.2000),
  total_payable    NUMERIC(12, 2) GENERATED ALWAYS AS (principal * (1 + interest_rate)) STORED,
  term_days        INTEGER NOT NULL CHECK (term_days >= 7 AND term_days <= 365),
  schedule_type    schedule_type NOT NULL,
  status           loan_status NOT NULL DEFAULT 'draft',
  purpose          TEXT,
  approved_by      UUID REFERENCES users(id) ON DELETE SET NULL,
  approved_at      TIMESTAMPTZ,
  disbursed_at     TIMESTAMPTZ,
  due_at           TIMESTAMPTZ,
  penalty_amount   NUMERIC(12, 2) DEFAULT 0,
  final_balance    NUMERIC(12, 2),
  defaulted_at     TIMESTAMPTZ,
  idempotency_key  TEXT UNIQUE,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at       TIMESTAMPTZ
);

CREATE INDEX idx_loans_lender_id ON loans(lender_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_loans_status ON loans(status) WHERE deleted_at IS NULL;
CREATE INDEX idx_loans_due_at ON loans(due_at) WHERE deleted_at IS NULL;
CREATE INDEX idx_loans_idempotency_key ON loans(idempotency_key) WHERE deleted_at IS NULL;

CREATE TABLE loan_co_makers (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  loan_id      UUID NOT NULL REFERENCES loans(id) ON DELETE CASCADE,
  co_maker_id  UUID NOT NULL REFERENCES co_makers(id) ON DELETE CASCADE,
  UNIQUE(loan_id, co_maker_id)
);

CREATE INDEX idx_loan_co_makers_loan_id ON loan_co_makers(loan_id);
CREATE INDEX idx_loan_co_makers_co_maker_id ON loan_co_makers(co_maker_id);

CREATE TABLE loan_schedules (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  loan_id            UUID NOT NULL REFERENCES loans(id) ON DELETE CASCADE,
  installment_number INTEGER NOT NULL,
  amount_due         NUMERIC(12, 2) NOT NULL,
  due_date           DATE NOT NULL,
  status             installment_status NOT NULL DEFAULT 'pending',
  paid_at            TIMESTAMPTZ,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_loan_schedules_loan_id ON loan_schedules(loan_id);
CREATE INDEX idx_loan_schedules_due_date ON loan_schedules(due_date) WHERE status = 'pending';
CREATE INDEX idx_loan_schedules_status ON loan_schedules(status);

CREATE TABLE payments (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  loan_id             UUID NOT NULL REFERENCES loans(id) ON DELETE RESTRICT,
  lender_id           UUID NOT NULL REFERENCES lenders(id) ON DELETE RESTRICT,
  amount              NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
  method              payment_method NOT NULL,
  status              payment_status NOT NULL DEFAULT 'pending',
  reference_number    TEXT,
  xendit_payment_id   TEXT,
  collected_by        UUID REFERENCES users(id) ON DELETE SET NULL,
  collected_at        TIMESTAMPTZ,
  receipt_url         TEXT,
  idempotency_key     TEXT UNIQUE,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at          TIMESTAMPTZ
);

CREATE INDEX idx_payments_loan_id ON payments(loan_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_payments_lender_id ON payments(lender_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_payments_status ON payments(status) WHERE deleted_at IS NULL;
CREATE INDEX idx_payments_idempotency_key ON payments(idempotency_key) WHERE deleted_at IS NULL;
CREATE INDEX idx_payments_xendit_id ON payments(xendit_payment_id) WHERE xendit_payment_id IS NOT NULL;

CREATE TABLE disbursements (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  loan_id                 UUID NOT NULL REFERENCES loans(id) ON DELETE CASCADE,
  method                  disbursement_method NOT NULL DEFAULT 'office',
  status                  disbursement_status NOT NULL DEFAULT 'pending',
  assigned_rider_id       UUID REFERENCES riders(id) ON DELETE SET NULL,
  xendit_disbursement_id  TEXT,
  gps_latitude            DOUBLE PRECISION,
  gps_longitude           DOUBLE PRECISION,
  delivered_at            TIMESTAMPTZ,
  receipt_url             TEXT,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at              TIMESTAMPTZ
);

CREATE INDEX idx_disbursements_loan_id ON disbursements(loan_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_disbursements_rider_id ON disbursements(assigned_rider_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_disbursements_status ON disbursements(status) WHERE deleted_at IS NULL;

CREATE TABLE collections (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  loan_id             UUID NOT NULL REFERENCES loans(id) ON DELETE CASCADE,
  lender_id           UUID NOT NULL REFERENCES lenders(id) ON DELETE RESTRICT,
  amount              NUMERIC(12, 2) NOT NULL,
  method              payment_method NOT NULL DEFAULT 'office',
  status              collection_status NOT NULL DEFAULT 'pending',
  assigned_rider_id   UUID REFERENCES riders(id) ON DELETE SET NULL,
  gps_latitude        DOUBLE PRECISION,
  gps_longitude       DOUBLE PRECISION,
  collected_at        TIMESTAMPTZ,
  photo_receipt_url   TEXT,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at          TIMESTAMPTZ
);

CREATE INDEX idx_collections_loan_id ON collections(loan_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_collections_lender_id ON collections(lender_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_collections_rider_id ON collections(assigned_rider_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_collections_status ON collections(status) WHERE deleted_at IS NULL;

CREATE TABLE documents (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lender_id       UUID NOT NULL REFERENCES lenders(id) ON DELETE CASCADE,
  document_type   document_type NOT NULL,
  file_url        TEXT NOT NULL,
  status          document_status NOT NULL DEFAULT 'pending',
  reviewed_by     UUID REFERENCES users(id) ON DELETE SET NULL,
  reviewed_at     TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at      TIMESTAMPTZ
);

CREATE INDEX idx_documents_lender_id ON documents(lender_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_documents_type ON documents(document_type) WHERE deleted_at IS NULL;
CREATE INDEX idx_documents_status ON documents(status) WHERE deleted_at IS NULL;

CREATE TABLE otp_codes (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  code_hash   TEXT NOT NULL,
  expires_at  TIMESTAMPTZ NOT NULL,
  is_used     BOOLEAN NOT NULL DEFAULT false,
  attempts    INTEGER NOT NULL DEFAULT 0,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_otp_codes_user_id ON otp_codes(user_id);
CREATE INDEX idx_otp_codes_expires ON otp_codes(expires_at) WHERE is_used = false;

CREATE TABLE audit_logs (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID REFERENCES users(id) ON DELETE SET NULL,
  user_role   TEXT,
  action      VARCHAR(100) NOT NULL,
  entity_type VARCHAR(50),
  entity_id   UUID,
  old_value   JSONB,
  new_value   JSONB,
  ip_address  INET,
  user_agent  TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_action ON audit_logs(action);
CREATE INDEX idx_audit_logs_entity ON audit_logs(entity_type, entity_id);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at);

CREATE TABLE notifications (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type       notification_type NOT NULL,
  title      TEXT NOT NULL,
  body       TEXT NOT NULL,
  data       JSONB,
  is_read    BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_notifications_user_id ON notifications(user_id) WHERE is_read = false;
CREATE INDEX idx_notifications_type ON notifications(type);

CREATE TABLE idempotency_keys (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key           VARCHAR(255) NOT NULL UNIQUE,
  response_body JSONB,
  status_code   INTEGER NOT NULL DEFAULT 200,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at    TIMESTAMPTZ NOT NULL
);

CREATE INDEX idx_idempotency_keys_key ON idempotency_keys(key);
CREATE INDEX idx_idempotency_keys_expires ON idempotency_keys(expires_at);

CREATE TABLE system_settings (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  interest_rate           NUMERIC(5, 4) NOT NULL DEFAULT 0.2000,
  penalty_rate            NUMERIC(5, 4) NOT NULL DEFAULT 0.2000,
  penalty_threshold_days  INTEGER NOT NULL DEFAULT 30,
  sms_templates           JSONB NOT NULL DEFAULT '{}'::jsonb,
  notification_preferences JSONB NOT NULL DEFAULT '{}'::jsonb,
  system_flags            JSONB NOT NULL DEFAULT '{}'::jsonb,
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_by              UUID REFERENCES users(id) ON DELETE SET NULL
);

INSERT INTO system_settings (interest_rate, penalty_rate, penalty_threshold_days)
VALUES (0.2000, 0.2000, 30);

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER trg_loans_updated_at
  BEFORE UPDATE ON loans
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER trg_disbursements_updated_at
  BEFORE UPDATE ON disbursements
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER trg_collections_updated_at
  BEFORE UPDATE ON collections
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER trg_system_settings_updated_at
  BEFORE UPDATE ON system_settings
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, full_name, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
    COALESCE((NEW.raw_app_meta_data->>'role')::user_role, 'lender')
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
