# Supabase Integration Notes

The app now supports a backend bootstrap path based on environment variables:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

If those variables are missing, the app falls back to mock services and seeded data.

## Current state
- `ServiceContainer.bootstrap()` chooses between mock and Supabase-backed service scaffolds.
- Supabase auth/profile scaffolding is in place.
- Lead and notification services now have DTO mapping and repository scaffolding against the schema.
- Session persistence now uses a Keychain-backed store on iOS.
- Core auth, lead, status-history, and notification flows were live-validated against the configured Supabase project on March 21, 2026 (America/Los_Angeles).
- Cross-user notification inserts must use `Prefer: return=minimal`. Asking PostgREST for `return=representation` can fail under RLS because the sender is not allowed to read the recipient's notification row.
- Some service methods still need stronger error handling and periodic re-validation after schema or policy changes.

## Files
- `SolarCRMApp/Core/Configuration/BackendConfiguration.swift`
- `SolarCRMApp/Core/Services/SupabaseAuthService.swift`
- `SolarCRMApp/Core/Services/SupabaseLeadService.swift`
- `SolarCRMApp/Core/Services/SupabaseNotificationService.swift`

## Next implementation steps
1. Add stronger backend error surfacing and retry behavior.
2. Disable debug role login in production once live auth is enabled.
3. Add private image upload + OCR/AI edge function flow.

## Live Validation Status
- Verified:
  - Supabase email/password auth for manager, closer, door knocker, and a recreated second closer test account
  - `app_users` profile lookup by authenticated user ID
  - Door knocker lead insert against live RLS
  - Closer visibility into assigned leads
  - `lead_status_history` persistence for closer outcome and assignment changes
  - Reminder notification delivery
  - Mark-read flow for in-app notifications
  - Cross-user notification delivery for manager, closer, door knocker, and reassignment recipients
- Verified workflows:
  - `On Closer Schedule -> Appointment Run -> Closed`
  - Manager reassignment from one closer to another with notification fanout to new closer, previous closer, and door knocker

## Repeatable Validation Procedure
1. Confirm the app scheme or environment provides `SUPABASE_URL` and `SUPABASE_ANON_KEY` for the intended project.
2. Ensure every test auth user has a matching `public.app_users` row with the same UUID as `auth.users.id`.
3. Validate `/auth/v1/token?grant_type=password` for each role you plan to exercise.
4. Validate `GET /rest/v1/app_users?id=eq.<auth uid>` with the returned bearer token.
5. Insert a lead as the door knocker with `Prefer: return=minimal`, then insert the corresponding `lead_status_history` row.
6. Fetch assigned leads as the closer to confirm RLS visibility.
7. Insert cross-user notifications with `Prefer: return=minimal`, then fetch them as the recipient to confirm delivery.
8. Patch a recipient-owned notification to `is_read = true` and verify the updated row.
9. For outcome validation, patch the lead status, insert matching history rows, and then deliver the expected fanout notifications.
10. For reassignment validation, patch `assigned_closer_id`, insert the reassignment history row, and verify delivery to the new closer, previous closer, and door knocker.

## Test Account Note
- The second closer validation account was repaired by recreating it through the real Supabase signup flow and then attaching the matching `public.app_users` row, rather than inserting directly into `auth.*` tables.
