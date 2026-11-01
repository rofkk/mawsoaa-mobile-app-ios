# Sharjah Encyclopedia iOS App

A native iOS WebView application to browse the Sharjah Encyclopedia website (https://sharjah-encyclopedia.org/).

## Prerequisites

To build and run this app, you need:

1. **macOS** (required for iOS development)
2. **Xcode** (version 14.0 or later recommended)
   - Download from the Mac App Store: https://apps.apple.com/app/xcode/id497799835
   - Or download from Apple Developer: https://developer.apple.com/xcode/

## Setup Instructions

✅ **Project is already set up!** The Xcode project has been created and the WebView code is ready.

### How to Run the App

1. **Open the project in Xcode:**
   - Double-click `mawsoaa-mobile-app-ios.xcodeproj` in Finder
   - OR in Xcode: File → Open → Select the `.xcodeproj` file

2. **Select a device:**
   - Click the device menu at the top (next to the Play button)
   - Choose an iPhone simulator (e.g., "iPhone 15 Pro")

3. **Build and Run:**
   - Press `Cmd + R` or click the Play button ▶️
   - Wait for the build to complete
   - The app will launch in the simulator showing the Sharjah Encyclopedia website

### ⚠️ IMPORTANT: Enable Network Permissions

iOS blocks network requests by default. You MUST add network permissions:

**In Xcode:**
1. Select your project (blue icon) in the left navigator
2. Select the "mawsoaa-mobile-app-ios" target
3. Go to the "Info" tab
4. Right-click in the list and select "Add Row"
5. Type: `App Transport Security Settings`
6. Expand it, click "+", add: `Allow Arbitrary Loads` → Set to `YES`
7. Build and run again (`Cmd + R`)

See `Info-Settings.txt` for detailed instructions.

### Editing the Code

You can edit the Swift files in **VS Code** or any editor you prefer:

- The main WebView code is in: `mawsoaa-mobile-app-ios/ContentView.swift`
- After making changes, just build again in Xcode (`Cmd + R`)

## Project Structure

```
mawsoaa-mobile-app-ios/
├── mawsoaa_mobile_app_iosApp.swift  # Main app entry point
├── ContentView.swift                 # Main view with WebView
└── Assets.xcassets/                  # App icons and assets
```

## Running the App

### On Simulator:

1. Open the project in Xcode
2. Select a simulator from the device menu (e.g., "iPhone 15 Pro")
3. Press `Cmd + R` or click the Play button
4. The app will build and launch in the simulator

### On Physical Device:

1. Connect your iPhone/iPad via USB
2. Select your device from the device menu
3. You may need to:
   - Trust your computer on the device
   - Enable "Developer Mode" in Settings → Privacy & Security
   - Sign the app with your Apple ID in Xcode (Signing & Capabilities tab)
4. Press `Cmd + R` to build and run

## Features

- ✅ Full WebView integration with WKWebView
- ✅ Back/forward navigation gestures
- ✅ Secure HTTPS connection to sharjah-encyclopedia.org
- ✅ Support for both iPhone and iPad
- ✅ Portrait and landscape orientations
- ✅ Native iOS performance

## App Store Submission

To submit to the App Store, you'll need:

1. **Apple Developer Account** ($99/year)
   - Sign up at: https://developer.apple.com/programs/

2. **App Icons**
   - Create icons in various sizes (see Assets.xcassets/AppIcon.appiconset/)
   - Use tools like: https://appicon.co/

3. **Screenshots**
   - Take screenshots on various device sizes
   - Required for App Store listing

4. **App Store Connect Setup**
   - Create app listing at: https://appstoreconnect.apple.com/
   - Fill in app description, keywords, privacy policy, etc.

5. **Archive and Upload**
   - In Xcode: Product → Archive
   - Use the Organizer to upload to App Store Connect
   - Submit for review

## Troubleshooting

### "Command Line Tools" Error
If you see errors about command line tools, install full Xcode from the App Store.

### Certificate/Signing Issues
- Go to Xcode → Settings → Accounts
- Add your Apple ID
- In project settings → Signing & Capabilities, select your team

### WebView Not Loading
- Check internet connection
- Verify the URL is correct in `ContentView.swift`
- Check App Transport Security settings in `Info.plist`

## Customization

### Change the Website URL
Edit `ContentView.swift`, line 7:
```swift
WebView(url: URL(string: "https://your-website.com/")!)
```

### Change App Name
Edit `Info.plist`:
```xml
<key>CFBundleDisplayName</key>
<string>Your App Name</string>
```

### Add Loading Indicator
Uncomment and implement the loading indicator code in the `Coordinator` class.

## Support

For iOS development help:
- Apple Developer Documentation: https://developer.apple.com/documentation/
- Swift Documentation: https://swift.org/documentation/
- SwiftUI Tutorials: https://developer.apple.com/tutorials/swiftui

## License

This is a simple WebView wrapper. Make sure you have permission to create an app for the website you're displaying.
