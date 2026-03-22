# Solar CRM Security Checklist

This checklist maps the app's security work into concrete implementation areas for the iOS client and Supabase backend.

## Must-Have For MVP

### 1. Real authentication
- Status: Not done
- iOS:
  - Replace mock login flow in `SolarCRMApp/Features/Auth/LoginView.swift`
  - Replace mock auth bootstrapping in `SolarCRMApp/Core/AppState.swift`
  - Store session securely in Keychain
- Backend:
  - Use Supabase Auth for Apple, Google, and email/password
  - Create a post-auth profile bootstrap for app roles

### 2. Backend-enforced roles
- Status: Not done
- iOS:
  - Remove production access to debug role switching in `LoginView`
  - Route from authenticated user profile only
- Backend:
  - Store role on `app_users`
  - Enforce role-based access through RLS policies

### 3. Row-level authorization
- Status: Schema drafted, not integrated
- iOS:
  - Treat backend as source of truth for all lead queries
- Backend:
  - Enforce:
    - door knocker can read/write only their own leads where appropriate
    - closer can read only assigned leads
    - manager can read org-wide leads
  - Base file: `Backend/supabase_schema.sql`

### 4. Org isolation
- Status: Schema drafted, not integrated
- iOS:
  - Do not trust client-side org filtering
- Backend:
  - Every user and lead query must be scoped by `org_id`

### 5. HTTPS-only traffic
- Status: Pending live integration
- iOS:
  - All API traffic through `SolarCRMApp/Core/Networking/APIClient.swift`
  - Do not allow non-TLS endpoints
- Backend:
  - Supabase endpoints are HTTPS

### 6. Secure token storage
- Status: Not done
- iOS:
  - Add Keychain-backed session storage
  - Do not store auth tokens in `UserDefaults`

### 7. No admin secrets in app
- Status: Not done
- iOS:
  - Only public anon/client keys may ship in the app
- Backend:
  - Service role keys stay server-side only

### 8. Private image handling
- Status: Not done
- iOS:
  - Do not persist note images longer than needed
  - Avoid debug logging image metadata/content
- Backend:
  - Store uploaded note images in private buckets
  - Use authenticated upload URLs

### 9. Audit trail
- Status: Partially done
- iOS:
  - `statusHistory` already modeled in `Lead`
- Backend:
  - Persist `lead_status_history`
  - Ensure every status/assignment change is written server-side

### 10. Disable dev shortcuts in production
- Status: Not done
- iOS:
  - Restrict `Developer Quick Access` in `LoginView` to debug builds only
  - Remove before release if live auth is present

### 11. Privacy policy
- Status: Not done
- Product:
  - Document handling of homeowner PII, note images, and AI/OCR processing

## Should-Have Before Beta

### 1. Session expiration and refresh
- iOS:
  - Handle expired access tokens
  - Rehydrate session on app launch
- Backend:
  - Standard Supabase refresh-token flow

### 2. Forced logout on invalid session
- iOS:
  - If session fetch fails or token is invalid, clear local state and return to auth

### 3. Backend status transition validation
- iOS:
  - UI can guide transitions, but backend must validate them
- Backend:
  - Prevent invalid jumps such as:
    - `Submitted -> Closed`
    - `Pending Confirmation -> Appointment Run`

### 4. Input validation and sanitization
- iOS:
  - Continue form validation in `LeadFormDraft`
- Backend:
  - Validate server-side too
  - Sanitize free-text fields such as notes

### 5. Notification deduplication
- iOS:
  - Already partially handled for reminder requests
- Backend:
  - Notification events should be generated server-side when possible

### 6. Minimal local caching
- iOS:
  - Avoid persisting sensitive lead data offline unless explicitly needed

### 7. Redacted logging
- iOS:
  - Do not log names, phone numbers, addresses, raw OCR text, or tokens

### 8. Signed image upload flow
- Backend:
  - Signed upload or secure authenticated storage path for note images

### 9. Rate limiting and abuse protection
- Backend:
  - Protect auth and AI endpoints from abuse

### 10. Safe error handling
- iOS:
  - Show user-friendly errors
  - Avoid exposing raw backend payloads

## Should-Have Before App Store Launch

### 1. Full audit log
- Backend:
  - Store actor, action, timestamp, and changed fields

### 2. Data retention and deletion
- Backend:
  - Support customer deletion and retention rules

### 3. Biometric protection
- iOS:
  - Consider Face ID/Touch ID re-entry for active sessions

### 4. Admin account controls
- Backend:
  - Role changes
  - user deactivation
  - org membership management

### 5. Monitoring and alerting
- Backend:
  - Watch auth failures, policy denials, and upload/API failures

### 6. Third-party AI/OCR review
- Product/Backend:
  - Confirm vendor retention and privacy terms

### 7. Authorization review
- Backend:
  - Test role and org boundaries intentionally

### 8. App Store privacy disclosures
- Product:
  - Complete privacy nutrition labels accurately

## Current Code Mapping

### iOS files
- Auth UI:
  - `SolarCRMApp/Features/Auth/LoginView.swift`
- App session and workflow orchestration:
  - `SolarCRMApp/Core/AppState.swift`
- Lead workflows:
  - `SolarCRMApp/Features/DoorKnocker/`
  - `SolarCRMApp/Features/Closer/`
  - `SolarCRMApp/Features/Manager/`
- Networking seam:
  - `SolarCRMApp/Core/Networking/APIClient.swift`
- Mock AI extraction seam:
  - `SolarCRMApp/Core/Services/AIExtractionService.swift`

### Backend files
- Schema and policies:
  - `Backend/supabase_schema.sql`
- Backend overview:
  - `Backend/README.md`

## Recommended Next Security Implementation Order
1. Add Supabase auth and profile bootstrap.
2. Replace mock lead and notification services with real repositories.
3. Enforce row-level security with real session identity.
4. Move image intake to private upload + OCR/AI endpoint.
5. Remove production debug login shortcuts.
