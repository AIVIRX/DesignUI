# AdMob Native Ads Setup Guide

This guide will help you complete the AdMob native ads integration in your DesignUI app.

## Prerequisites

1. A Google AdMob account
2. An AdMob app registered in your account
3. A Native Ad Unit ID (you'll create this in AdMob)

## Steps to Complete Integration

### 1. Add Google Mobile Ads SDK

#### Via Swift Package Manager (Recommended):

1. Open your Xcode project
2. Go to **File > Add Package Dependencies...**
3. Enter the URL: `https://github.com/googleads/swift-package-manager-google-mobile-ads.git`
4. Select the latest version (or a specific version like `11.0.0`)
5. Add it to your `DesignUI` target

### 2. Update AdMob Configuration

1. Open `DesignUI/Core/Utilities/AdManager.swift`
2. Replace the test ad unit ID with your actual Native Ad Unit ID:
   ```swift
   private let adUnitID: String = "YOUR_ACTUAL_AD_UNIT_ID_HERE"
   ```

### 3. Configure AppDelegate (if not already done)

The code tries to get the root view controller, but you may need to ensure GADMobileAds is initialized early. Update your `DesignUIApp.swift`:

```swift
#if os(iOS)
import GoogleMobileAds

class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Initialize AdMob early
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        
        UserDefaults.standard.set(0, forKey: "selectedIndex")
        
        // Configure RevenueCat
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: "appl_NcISLizYLMfgkTRcyMMCXrbTBFC")
        
        return true
    }
}
#endif
```

### 4. Update Info.plist

Add your AdMob App ID to `Info.plist`:

1. Open `Info.plist`
2. Add a new key: `GADApplicationIdentifier`
3. Set its value to your AdMob App ID (format: `ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX`)

Or add this to your Info.plist file:
```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX</string>
```

### 5. Fix Root View Controller Access

Update `AdManager.swift` to properly get the root view controller:

```swift
func loadNativeAd(for identifier: String) {
    #if os(iOS)
    // Check if ad already loaded for this identifier
    if nativeAds[identifier] != nil {
        return
    }
    
    // Get root view controller - updated method for iOS 13+
    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let rootViewController = windowScene.windows.first?.rootViewController else {
        print("Could not get root view controller for ad loading")
        return
    }
    
    // Create or reuse ad loader for this identifier
    let adLoader = GADAdLoader(
        adUnitID: adUnitID,
        rootViewController: rootViewController,
        adTypes: [.native],
        options: nil
    )
    adLoader.delegate = AdLoaderDelegate(identifier: identifier, adManager: self)
    adLoaders[identifier] = adLoader
    
    let request = GADRequest()
    adLoader.load(request)
    #endif
}
```

## Features

- ✅ Native ads appear inline with posts
- ✅ Ads are inserted every 5-10 posts (randomized)
- ✅ Ads work in both masonry and grid layouts
- ✅ Loading states and error handling included
- ✅ Ads are cached to avoid reloading
- ✅ **AdMob Compliant**: Includes all required elements:
  - "Ad" badge at the top (20x20 pixels, exceeds minimum 15x15)
  - Visual separation with shadow/elevation
  - Call to action button
  - AdChoices icon (automatically added by SDK in top-right)
  - Proper spacing and legibility

## Testing

Use Google's test ad unit ID for development:
- **Native Ad**: `ca-app-pub-3940256099942544/3986624511`

## Notes

- Ads only appear on iOS (macOS version shows empty view)
- Make sure you have a valid AdMob account and ad unit created
- Native ads must be configured in AdMob console as "Native" ad format
- The ad interval (5-10 posts) is randomized per feed load

## AdMob Compliance

The implementation includes all AdMob requirements:

1. **Ad Attribution**: "Ad" badge (20x20 pixels) at the top of each ad
2. **AdChoices Icon**: Automatically added by the SDK in the top-right corner. Ensure it's visible - the SDK handles placement
3. **Visual Separation**: Shadow/elevation applied to distinguish ads from content
4. **Call to Action**: Button included at the bottom of each ad
5. **Legibility**: All text is readable with proper font sizes and contrast
6. **No Overlapping**: All elements are properly constrained with Auto Layout

The ad view is designed to blend with your app's design while clearly identifying itself as an advertisement.

## Troubleshooting

- **Ads not showing**: Check that AdMob SDK is properly added and App ID is in Info.plist
- **Root view controller error**: Ensure the app has finished launching before loading ads
- **Ad loading fails**: Verify your Ad Unit ID is correct and the ad unit is active in AdMob

