# Jireta Loan

A multi-platform lending management system for Jireta Lending Corp. Built with Flutter (mobile + web) on the frontend and Supabase + PostgreSQL + TypeScript Edge Functions on the backend.

## Architecture Overview

### Frontend (Flutter)
- **State management:** Riverpod 2
- **Navigation:** go_router 14
- **HTTP:** Dio 5 (with interceptors: auth, retry, error, idempotency, logging)
- **Realtime:** Supabase realtime channels via `RealtimeClient` wrapper
- **UI:** Material 3 with custom color tokens, animated transitions, interactive cards, shimmer loading, pulse dots, animated counters

### Backend (Supabase)
- **Database:** PostgreSQL (3NF schema, RLS policies)
- **Auth:** Supabase Auth (email/password + Google OAuth)
- **Edge Functions:** TypeScript Deno functions for all sensitive business logic
- **Realtime:** Postgres changes broadcast via Supabase Realtime

### Role System

| Display Name      | Enum Value      | Capabilities                                  |
|-------------------|-----------------|-----------------------------------------------|
| Head Manager      | `head_manager`  | Full system access, user management, audit    |
| Employee          | `employee`      | Loan approval, lender management, collections |
| Rider             | `rider`         | Disbursement & collection tasks, GPS check-in |
| Lender            | `lender`        | Loan applications, payments, KYC upload       |

## Database Schema (3NF)

The schema follows third normal form with:
- Atomic values (no arrays/JSON in place of normalized tables)
- No transitive dependencies
- Foreign keys with appropriate cascade rules
- Partial indexes for soft-deleted records
- Generated columns for computed values (e.g., `total_payable`)

**Tables:** `users`, `lenders`, `lender_phones`, `co_makers`, `riders`, `loans`, `loan_co_makers`, `loan_schedules`, `payments`, `disbursements`, `collections`, `documents`, `otp_codes`, `audit_logs`, `notifications`, `idempotency_keys`, `system_settings`

**Migrations:**
1. `0001_init_schema.sql` — Tables, enums, triggers
2. `0002_rls_policies.sql` — Row-Level Security policies + role helper functions (in `public` schema, not `auth`)
3. `0003_triggers.sql` — Audit logging, loan status guard, auto-schedule generation, penalty computation
4. `0004_audit_log.sql` — Performance indexes, materialized views, pg_cron jobs
5. `0005_realtime.sql` — Realtime publication for all transactional tables

## Sensitive Business Logic (Backend TS)

All sensitive computations and operations live in TypeScript Edge Functions:

- **`_shared/loan-finance.ts`** — Loan terms validation, total payable calculation, installment schedule generation, penalty computation, collection efficiency
- **`_shared/payments.ts`** — Payment processing with idempotency, outstanding balance validation, automatic loan status transitions, notification dispatch
- **`_shared/jwt.ts`** — JWT verification, role-based access control (`hasRole`, `requireRole`)
- **`_shared/supabase.ts`** — Service-role Supabase client (bypasses RLS for system operations)
- **`_shared/cors.ts`**, **`_shared/errors.ts`**, **`_shared/validation.ts`** — Cross-cutting concerns

**Edge Functions:**
- `auth/otp-send`, `auth/otp-verify`, `auth/google-callback`
- `loans/create`, `loans/list`, `loans/detail`, `loans/approve`, `loans/reject`, `loans/compute-penalty`
- `payments/create`, `payments/list`
- `disbursements/assign-rider`, `disbursements/mark-delivered`
- `collections/assign-rider`, `collections/mark-collected`
- `rider/today`, `rider/gps-checkin`
- `reports/portfolio`, `reports/overdue`
- `notifications/send-sms`, `notifications/send-email`, `notifications/send-push`
- `webhooks/xendit`, `webhooks/sms-status`
- `health`

## Communication Layer

```
Flutter (Dart)
  │
  ├─ Supabase Auth SDK ──── auth.users (Postgres)
  ├─ Supabase Realtime ──── supabase_realtime publication
  ├─ Supabase Storage ───── kyc-documents bucket
  │
  ├─ Dio HTTP ─── Edge Functions (TypeScript)
  │                  ├─ Service-role Supabase client (RLS bypass)
  │                  ├─ Business rule enforcement
  │                  └─ Xendit / SMS / Email / Push third-party APIs
  │
  └─ Direct Supabase queries (RLS-protected)
       └─ public.* tables + views + functions
```

## Setup

### Prerequisites
- Flutter 3.12+ / Dart 3.12+
- Supabase CLI 1.50+
- Node 18+ (for Edge Function local dev)

### Local Development

```bash
# Install Flutter deps
flutter pub get

# Run Supabase locally
cd supabase
supabase start
supabase db reset  # Apply all migrations

# Set environment variables (create .env or pass via --dart-define)
SUPABASE_URL=http://localhost:54321
SUPABASE_ANON_KEY=your-anon-key

# Run the app
flutter run -d chrome    # Web
flutter run -d ios       # iOS
flutter run -d android   # Android
```

### Edge Functions

```bash
# Deploy all functions
supabase functions deploy auth-otp-send
supabase functions deploy loans-create
# ... etc

# Set secrets
supabase secrets set XENDIT_WEBHOOK_TOKEN=...
supabase secrets set TWILIO_AUTH_TOKEN=...
supabase secrets set JWT_SECRET=...
supabase secrets set CRON_SECRET=...
```

## Fixes Applied in This Refactor

### SQL Errors Fixed
1. **`permission denied for schema auth`** — Moved all role helper functions (`is_admin`, `is_manager`, `is_borrower`, `user_role`, `current_user_id`) from `auth.*` to `public.*` schema.
2. **`column b.full_name does not exist`** — Fixed `v_overdue_loans` and `v_rider_tasks` views to JOIN `users` table for `full_name` and `phone` (these columns don't exist on `lenders` table per 3NF — they live on `users`).

### Naming Refactor
- Package: `lendflow` → `jireta_loan`
- Display name: `LendFlow` → `Jireta Loan`
- Roles: `admin` → `head_manager`, `manager` → `employee`, `borrower` → `lender`
- Tables: `borrowers` → `lenders`, `borrower_phones` → `lender_phones`
- Columns: `borrower_id` → `lender_id`, `borrower_name` → `lender_name`, etc.

### Flutter Analysis Errors Fixed (235 total)
- **62** `deprecated_member_use` — `withOpacity()` → `withValues(alpha:)`
- **83** `prefer_initializing_formals` — Disabled (style-only) in `analysis_options.yaml`
- **17** `unused_import` — Removed
- **6** `ambiguous_import` — Renamed local `AuthState` → `AppAuthState`, local `AuthException` → `AppAuthException`
- **4** `argument_type_not_assignable` — Fixed `String?` → `int?` conversions in document data source
- **2** `non_abstract_class_inherits_abstract_member` — Changed `implements TokenStorage` → `extends TokenStorage`
- **1** `non_exhaustive_switch_statement` — Added `DioExceptionType.transformTimeout` case
- **4** `const_with_non_const` — Removed `const` from non-const interceptor constructors
- **4** `undefined_identifier` (`ColorTokens`, `AppConstants`) — Added missing imports
- **1** `undefined_class` (`IconData`) — Added `flutter/material.dart` import
- **3** `invalid_constant` — Removed `const` from constructors using `DateTime.now()`
- **1** `uri_does_not_exist` + `creation_with_non_type` — Replaced default Flutter test with real test
- **2** `directive_after_declaration` — Reorganized imports in `main.dart`
- **2** `undefined_function` (`setUrlStrategy`) — Added conditional web import pattern
- **3** `deprecated_member_use` (`anonKey`) — Replaced with `publishableKey`
- **2** `undefined_method` (`logout`) — Renamed to `signOut`
- **2** `undefined_getter` (`user`) — Fixed `AppAuthAuthenticated.user.id` → `AppAuthAuthenticated.userId`
- Various `unnecessary_underscores`, `unnecessary_brace_in_string_interps`, `use_null_aware_elements` — Disabled noisy style lints

### Database (3NF) Hardening
- Renamed `borrowers` → `lenders`, `borrower_phones` → `lender_phones`
- Added `entity_type` and `entity_id` to `audit_logs` for traceable audit trail
- Added `data` JSONB column to `notifications`
- Added `status_code` to `idempotency_keys`
- Added `user_agent` to `audit_logs`
- Added `is_primary` flag to `lender_phones`
- All helper functions moved to `public` schema with `SECURITY DEFINER`
- Added `public.compute_penalty_for_loan()` SQL function for penalty calculation
- Added `public.current_lender_id()` helper for RLS policies

### Realtime
- All transactional tables added to `supabase_realtime` publication
- `REPLICA IDENTITY FULL` on tables for complete before/after change data
- Realtime trigger function broadcasts change events
- Dart `RealtimeClient` wrapper provides typed subscriptions per table/user/role

### UI Interactivity
- `InteractiveCard` widget with hover, press, and elevation animations
- `PulseDot` for live status indicators
- `ShimmerLoading` for skeleton loading states
- `AnimatedCounter` for KPI number roll-up animations
- Login page redesigned with staggered entrance animations, shake-on-error, password visibility toggle, gradient background, animated logo
- `flutter_animate` integration for declarative animation chains

## License

Proprietary — Jireta Lending Corp..
