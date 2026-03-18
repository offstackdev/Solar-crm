# Solar CRM iOS MVP

Production-oriented SwiftUI starter for a solar sales CRM with:
- Door knocker lead intake
- Closer scheduling and outcomes
- Manager pipeline board and reassignment
- Mock AI image extraction review flow
- Supabase-ready backend schema

## Project structure

- `SolarCRMApp/`: SwiftUI app source
- `Backend/`: Supabase schema and backend notes
- `project.yml`: XcodeGen manifest for generating an Xcode project

## Generate Xcode project

```bash
xcodegen generate
```

## Notes

- The current implementation uses mock services and seeded data to keep the MVP runnable before backend integration.
- `SupabaseAPIClient` is included as the networking seam for moving from mocks to live services.
