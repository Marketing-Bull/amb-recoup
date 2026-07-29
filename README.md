# Recoup

Track every billable hour, mile, and dollar on client projects — and recoup it.

- **Single SwiftUI multiplatform app** — iPhone, iPad, and Mac from one codebase (iOS 17+ / macOS 14+)
- **SwiftData** on-device persistence + **CloudKit** private-database sync (iPhone ↔ iPad ↔ Mac, automatic), including the shared mileage-rate setting
- **No server.** Nothing to host, nothing to maintain.

## Features

- **Time** — log hours with preset chips (no keyboard), the hourly rate resolves project → client and is **locked at save**, filtered totals, CSV export
- **Mileage** — trips with round-trip doubling, one-tap "repeat a recent trip", deductible + billable stats at the global rate (Settings, default $0.67/mi), CSV export
- **Expenses** — amount-first entry, tappable category grid, recurring badge with annualized value, receipt photos (camera or library, compressed before save), CSV export
- **Clients & Projects** — hourly rates with per-project overrides, archive instead of delete
- **Dashboard** — date-range presets with six summary cards and a per-client / per-project breakdown
- **Settings** — mileage rate, import sample data to try the app, export a full CSV backup of everything, reset all data
- **Low-typing everywhere** — forms prefill your last-used client + project, recent-pair chips, smart defaults (date = today, time billable ON, expenses default to last category)

## One-time setup

1. **Prereqs:** Xcode 16+, Homebrew, and a paid Apple Developer account (needed for CloudKit sync — see step 7 if you don't have one).
2. Install XcodeGen:
   ```sh
   brew install xcodegen
   ```
3. Edit `project.yml`: set `DEVELOPMENT_TEAM` to your 10-character team ID (Xcode → Settings → Accounts).
4. Edit both files in `Recoup/Support/*.entitlements`: set the iCloud container ID (`iCloud.com.marketingbull.recoup`, or matching your bundle ID if you changed it).
5. Generate and open the project:
   ```sh
   xcodegen generate
   open RecoupBull.xcodeproj
   ```
6. Build and run on both "My Mac" and your iPhone. The first signed device build auto-creates the CloudKit container. **Sync test:** sign both devices into the same iCloud account; create a client, project, and entry on one device; confirm them on the other; then change the mileage rate and confirm that it updates there too.
7. **No paid developer account?** In `Recoup/RecoupApp.swift`, change `cloudKitDatabase: .automatic` to `.none` — the app becomes fully local and everything else works.

## Rules of the road

- **Never edit project settings inside Xcode.** The `.xcodeproj` is generated and gitignored — regeneration discards in-Xcode changes. Edit `project.yml` and re-run `xcodegen generate`.
- New Swift files under `Recoup/` are picked up automatically on the next `xcodegen generate`.
- CI builds both the iOS Simulator and macOS destinations and runs the unit tests on macOS (signing disabled) on every push.
