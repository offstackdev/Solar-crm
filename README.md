# Solar CRM iOS MVP

Production-oriented SwiftUI starter for a solar sales CRM with:
- Door knocker lead intake
- Closer scheduling and outcomes
- Manager pipeline board and reassignment
- Live AI image extraction review flow backed by Supabase
- Supabase-backed backend schema and services

## Project structure

- `SolarCRMApp/`: SwiftUI app source
- `Backend/`: Supabase schema and backend notes
- `project.yml`: XcodeGen manifest for generating an Xcode project

## Generate Xcode project

```bash
xcodegen generate
```

## Notes

- The app boots into live Supabase mode when `SUPABASE_URL` and `SUPABASE_ANON_KEY` are available. This branch also embeds those values into the generated app Info.plist for local device builds.
- The live workflow validated on March 22, 2026 is: `Image Upload -> OCR Review -> Save Lead -> Add Appointment Time -> Appointment Confirmed -> Closer Handoff`.
- Real-device runs are the source of truth for the AI intake path. The iOS simulator still shows intermittent CFNetwork protocol failures against Supabase Storage and Edge Functions for this workflow.
- Mock services remain as the fallback path only when backend configuration is unavailable.
