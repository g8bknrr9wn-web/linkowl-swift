# LinkOwl 🦉

Know which link drove each install. Attribution for indie iOS developers.

**Free to use. £0.02 per attributed purchase.**

## Install

Xcode → **File → Add Package Dependencies** → paste:

```
https://github.com/g8bknrr9wn-web/linkowl-swift
```

## Setup (one line)

```swift
import LinkOwl

@main
struct MyApp: App {
    init() {
        LinkOwl.start("lo_live_xxxx") // Your API key from linkowl.app
    }

    var body: some Scene {
        WindowGroup { ContentView() }
    }
}
```

That's it. Installs are now tracked and attributed to your LinkOwl tracking links.

## RevenueCat Users

Add one more line after your RevenueCat setup:

```swift
Purchases.configure(withAPIKey: "your_rc_key")
LinkOwl.setUserId(Purchases.shared.appUserID)
```

Then add the webhook in RevenueCat dashboard → Project Settings → Webhooks:
```
https://linkowl.app/api/v1/webhooks/revenuecat/YOUR_APP_ID
```

Purchases are now attributed automatically.

## Superwall Users

Same idea:

```swift
Superwall.configure(apiKey: "your_sw_key")
LinkOwl.setUserId(Superwall.shared.userId)
```

Webhook URL for Superwall:
```
https://linkowl.app/api/v1/webhooks/superwall/YOUR_APP_ID
```

## For AI Coding Tools

If you're using **Cursor**, **VibeCode**, **Windsurf**, or similar — paste this prompt:

> Add the LinkOwl SDK for install attribution. Swift Package URL: https://github.com/g8bknrr9wn-web/linkowl-swift — In the app's init, add: `import LinkOwl` then `LinkOwl.start("lo_live_xxxx")`. Replace xxxx with my API key from linkowl.app.

## API Reference

| Method | Description |
|--------|-------------|
| `LinkOwl.start(_ apiKey: String)` | Configure + track install. Call once on launch. |
| `LinkOwl.setUserId(_ userId: String)` | Link RevenueCat/Superwall user for purchase attribution. |
| `LinkOwl.trackPurchase(transactionId:revenue:currency:)` | Manual purchase tracking (only if not using webhooks). |

## How It Works

1. You create a tracking link at [linkowl.app](https://linkowl.app) (e.g. `linkowl.app/l/tiktok-campaign`)
2. Someone clicks it → fingerprint captured → redirected to App Store
3. They install your app → SDK calls `start()` → fingerprint matched to click
4. They purchase → webhook fires → purchase attributed to that link
5. You see the full chain in your dashboard: click → install → purchase

## Privacy

- **No IDFA / IDFV** — no Apple advertising identifiers
- **No persistent device IDs** — fingerprint uses hashed IP + device metadata
- **GDPR-safe** — IPs hashed with daily-rotating salt
- **< 50KB** — tiny bundle, no bloat
- **Silent** — never crashes your app

## Requirements

- iOS 16.0+
- Swift 5.9+

## License

MIT
