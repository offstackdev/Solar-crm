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
- Device builds can now read `SUPABASE_URL` and `SUPABASE_ANON_KEY` from the generated app Info.plist in addition to Xcode launch environment variables, which keeps physical-device runs out of mock mode.
- Core auth, lead, status-history, and notification flows were live-validated against the configured Supabase project on March 21, 2026 (America/Los_Angeles).
- Image intake upload, OCR extraction, review-before-save, appointment scheduling after save, and closer handoff were live-validated against the configured Supabase project on a physical iPhone on March 22, 2026 (America/Los_Angeles).
- Address parsing fallbacks and source-text review formatting were hardened in code on March 22, 2026, but those quality changes still need another live pass against a broader set of handwritten note samples.
- The iOS simulator still shows intermittent CFNetwork `cannot parse response` / protocol-violation failures against Supabase Storage and `lead-image-intake`, so simulator results should not be treated as authoritative for the live OCR path.
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
3. Re-validate the image intake OCR path after each Edge Function prompt/model change.

## Image Intake Backend Contract

The image intake flow now assumes a real Supabase-backed path:

1. The iOS client uploads the selected image bytes to the private storage bucket `lead-intake-images`.
2. The object path must start with the authenticated user's UUID folder, for example `<auth uid>/<generated file name>.jpg`.
3. The iOS client then invokes the Edge Function `lead-image-intake` with:
   - `bucket`
   - `objectPath`
   - `fileName`
   - `mimeType`
4. The Edge Function verifies the caller JWT, confirms the requested object path belongs to that user, downloads the private object with the service role, runs OCR, parses the OCR text into lead fields, and returns:
   - `draft`
   - `fieldConfidences`
   - `rawText`
5. The app opens the existing review/edit screen and only persists the lead if the user taps save.
6. After save, the door knocker can set or update the appointment time from the lead detail screen and then confirm handoff to the assigned closer.

Fallback behavior:

- If the direct client upload/invoke path fails with the simulator-only transport issue seen in CFNetwork (`cannot parse response`, protocol violation, prematurely closed stream), the app now retries image intake by sending the image inline to `lead-image-intake`.
- The Edge Function accepts either:
  - `bucket` + `objectPath`
  - or `inlineImageBase64`
- This fallback was added to keep development moving, but the physical-device path remains the primary validation target.

## Edge Function Auth Posture

The deployed `lead-image-intake` function currently runs with `verify_jwt = false` at the Supabase gateway.

That remains the recommended posture for this branch as of March 22, 2026.

Reasons:

- The live iOS bearer-token flow was validated with in-function auth checks and not with gateway JWT verification.
- Supabase now recommends handling Edge Function auth in application code for modern signing-key setups instead of relying on the older implicit gateway JWT check.
- Supabase troubleshooting guidance also notes that the gateway check can reject requests that use newer asymmetric key setups, and that the check adds limited security value by itself.

The function now enforces auth inside the handler by requiring:

- `Authorization: Bearer <token>`
- `supabase.auth.getUser(token)` to succeed
- a matching `public.app_users` row
- `app_users.role = 'door_knocker'`
- the uploaded object path to begin with the authenticated user's UUID folder

Repo note:

- `supabase/config.toml` now pins `[functions.lead-image-intake] verify_jwt = false` so future CLI deployments do not silently drift from the live-validated posture.

Recommendation:

- Keep gateway `verify_jwt` disabled for `lead-image-intake` until the team explicitly validates a replacement path end to end.
- If you want to revisit this later, do not rely on the old gateway check as the main hardening step. Instead, keep the current in-function bearer-token checks and, if needed, upgrade them to explicit JWT verification against Supabase signing keys or claims-based verification in the handler.
- Re-enabling gateway verification without a fresh live test against the exact iOS auth flow is likely to reintroduce the pre-handler 401 failure mode.

## Required Backend Files

- Storage/RLS SQL: `Backend/supabase_ai_intake.sql`
- Edge Function: `supabase/functions/lead-image-intake/index.ts`

## Required Secrets and Config

Existing app/runtime:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

Required for the deployed Edge Function:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`
- `OPENAI_API_KEY`

Optional Edge Function overrides:
- `OPENAI_OCR_MODEL` default: `gpt-4.1-mini`
- `OPENAI_PARSER_MODEL` default: same as `OPENAI_OCR_MODEL`
- `LEAD_INTAKE_BUCKET` default: `lead-intake-images`

## OpenAI API Surface Recommendation

Current implementation:

- The function uses OpenAI `chat/completions` for both OCR and structured lead parsing.

Recommendation as of March 22, 2026:

- Keep the live function on `chat/completions` for this branch right now.
- Revisit `responses` only when you are ready to run another live validation cycle and absorb a small refactor in both OCR-response parsing and JSON extraction parsing.

Why:

- The current workflow is already validated live end to end on `chat/completions`.
- This function does two narrow single-shot tasks: image OCR and schema-shaped parsing. It does not currently need the bigger stateful/tooling surface that makes `responses` more compelling.
- A migration today would create churn in a branch whose immediate priority is extraction quality and review UX hardening, not platform-surface expansion.

When `responses` becomes worth it:

- if you want one consistent endpoint across future multimodal workflows
- if you want to adopt newer models or features that land first or only on `responses`
- if you want richer structured-output or agent/tool orchestration patterns in the same intake pipeline

## Deployment Steps

1. Apply `Backend/supabase_ai_intake.sql` to the target Supabase project.
2. Set the Edge Function secrets listed above, especially `OPENAI_API_KEY`.
3. Deploy the `lead-image-intake` Edge Function with the current in-function auth checks.
4. Confirm the iOS app environment still provides `SUPABASE_URL` and `SUPABASE_ANON_KEY`.
5. Log in as a door knocker, import an image, confirm extracted fields appear on the review screen, edit as needed, and then save through the normal lead flow.
6. Open the saved lead, add an appointment time, and confirm the appointment to verify the closer handoff path.

## Validation Notes

- Verified live:
  - image picker reads real bytes instead of inventing a mock payload name
  - client uploads to authenticated private Supabase storage
  - client invokes the live `lead-image-intake` Edge Function
  - client falls back to inline function submission when simulator networking fails before a valid Supabase response is returned
  - OCR/AI returns a structured extraction payload
  - extracted fields prefill the review screen
  - review-before-save UX remains intact and image extraction does not auto-save
  - the reviewed image-intake lead saves through the existing Supabase-backed lead flow
  - a saved image-intake lead can later receive an appointment time on the detail screen
  - appointment confirmation still hands the lead off to the closer flow
- Still requires ongoing hardening / re-validation:
  - OCR quality across more real field note samples
  - address splitting accuracy for handwritten, labeled, two-line, and comma-free address formats after the March 22, 2026 fallback changes
  - raw source text readability on-device with long OCR payloads and messy handwritten spacing
  - whether the inline-image fallback should remain enabled for all debug builds or be more tightly scoped to development-only conditions
  - any future migration from `chat/completions` to `responses`
  - any attempt to re-enable gateway JWT verification for the iOS bearer-token flow

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
  - `Image Upload -> OCR Review -> Save Lead -> Add Appointment Time -> Appointment Confirmed -> Closer Handoff`

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
