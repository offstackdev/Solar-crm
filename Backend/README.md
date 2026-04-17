# Solar CRM Backend

This MVP is structured around Supabase.

Why Supabase:
- Native Postgres schema fits the CRM workflow and audit trail better than document storage.
- Row-level security maps directly to door knocker, closer, and manager permissions.
- It supports fast MVP iteration with auth, database, storage, and edge functions.

Planned service boundaries:
- `auth`: session + role bootstrap
- `leads`: create, list, update status, assign closer
- `notifications`: in-app inbox records
- `ai intake`: upload note image to storage, OCR/LLM parse via edge function, return extraction payload for review

Current intake implementation contract:
- private storage bucket: `lead-intake-images`
- edge function: `lead-image-intake`
- external AI secret required in Supabase Edge Functions: `OPENAI_API_KEY`
- current auth posture: gateway `verify_jwt` is intentionally disabled and the function enforces bearer-token auth, `app_users` presence, `door_knocker` role, and user-owned storage paths inside the handler
- repo deployment config now pins that posture in `supabase/config.toml`
