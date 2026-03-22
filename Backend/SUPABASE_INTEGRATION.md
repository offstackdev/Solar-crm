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
- Some service methods still need live-project validation and stricter error handling.

## Files
- `SolarCRMApp/Core/Configuration/BackendConfiguration.swift`
- `SolarCRMApp/Core/Services/SupabaseAuthService.swift`
- `SolarCRMApp/Core/Services/SupabaseLeadService.swift`
- `SolarCRMApp/Core/Services/SupabaseNotificationService.swift`

## Next implementation steps
1. Validate the live Supabase auth/profile flow against a real project.
2. Validate lead and notification repository calls against the deployed schema and RLS.
3. Add stronger backend error surfacing and retry behavior.
4. Disable debug role login in production once live auth is enabled.
5. Add private image upload + OCR/AI edge function flow.
