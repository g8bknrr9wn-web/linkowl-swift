# LinkOwl 🦉

Attribution tracking for indie iOS developers. Know which link, influencer, or campaign drove each install and purchase.

**Free to use. £0.02 per attributed purchase. That's it.**

## Installation

### Swift Package Manager

In Xcode: **File → Add Package Dependencies** → paste:

```
https://github.com/linkowl/linkowl-swift
```

Or add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/linkowl/linkowl-swift", from: "1.0.0")
]
```

## Quick Start (3 steps)

### 1. Configure on app launch

```swift
import LinkOwl

@main
struct MyApp: App {
    init() {
        LinkOwl.configure(apiKey: "lo_live_xxxx") // Get your key at linkowl.app
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### 2. Track installs

Call once after first launch. Safe to call multiple times — the SDK deduplicates automatically.

```swift
struct ContentView: View {
    var body: some View {
        Text("Hello")
            .onAppear {
                LinkOwl.trackInstall()
            }
    }
}
```

### 3. Connect RevenueCat (recommended)

If you use RevenueCat, add one line after your Purchases setup:

```swift
Purchases.configure(withAPIKey: "your_rc_key")
LinkOwl.setUserId(Purchases.shared.appUserID)
```

Then add the LinkOwl webhook URL in your RevenueCat dashboard:
1. Go to **RevenueCat → Project Settings → Webhooks**
2. Add endpoint: `https://linkowl.app/api/v1/webhooks/revenuecat/YOUR_APP_ID`
3. Done. Purchases are now automatically attributed.

## API Reference

### `LinkOwl.configure(apiKey:baseURL:)`

Configure the SDK. Call once on app startup.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `apiKey` | `String` | ✅ | Your API key (starts with `lo_live_`) |
| `baseURL` | `String?` | ❌ | Override API URL (testing only) |

### `LinkOwl.trackInstall()`

Track an app install. Collects a privacy-safe fingerprint (no IDFA/IDFV) and sends it to LinkOwl for attribution matching.

- **Idempotent** — only fires once per device, even if called multiple times
- **Non-blocking** — runs in background, never blocks main thread
- **Silent** — never crashes your app, logs errors to os_log only

### `LinkOwl.setUserId(_ userId: String)`

Set the RevenueCat user ID for automatic purchase attribution via webhook.

| Parameter | Type | Description |
|-----------|------|-------------|
| `userId` | `String` | RevenueCat `appUserID` |

### `LinkOwl.trackPurchase(transactionId:revenue:currency:)`

Manually track a purchase. **Only needed if you're NOT using the RevenueCat webhook.**

| Parameter | Type | Description |
|-----------|------|-------------|
| `transactionId` | `String` | Unique transaction ID |
| `revenue` | `Double` | Purchase amount (e.g. `4.99`) |
| `currency` | `String` | ISO 4217 code (e.g. `"GBP"`) |

## How It Works

```
User clicks your LinkOwl tracking link
    → Fingerprint captured (IP hash, device info)
    → Redirected to App Store

User installs your app
    → SDK calls trackInstall()
    → Fingerprint matched to click
    → Install attributed to link/campaign

User makes a purchase
    → RevenueCat webhook fires
    → Purchase attributed to original link
    → You see it in your dashboard
```

## Privacy

- **No IDFA / IDFV** — we never collect Apple advertising identifiers
- **No persistent device IDs** — fingerprint uses IP hash + device metadata only
- **IP hashing** — IPs are hashed with a daily-rotating salt (GDPR-safe)
- **Minimal data** — we collect only what's needed for attribution matching
- **< 50KB** — tiny bundle size, no bloat

## Full SwiftUI Example

```swift
import SwiftUI
import LinkOwl
import RevenueCat

@main
struct BrushSquadApp: App {
    init() {
        // 1. Configure LinkOwl
        LinkOwl.configure(apiKey: "lo_live_84f85940f8539667f335bd1cea0ec8aa")
        
        // 2. Configure RevenueCat
        Purchases.configure(withAPIKey: "your_rc_api_key")
        
        // 3. Link them
        LinkOwl.setUserId(Purchases.shared.appUserID)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // 4. Track install
                    LinkOwl.trackInstall()
                }
        }
    }
}
```

## Requirements

- iOS 16.0+
- Swift 5.9+
- Xcode 15+

## License

MIT — see [LICENSE](LICENSE).

---

**Dashboard & docs:** [linkowl.app](https://linkowl.app)
