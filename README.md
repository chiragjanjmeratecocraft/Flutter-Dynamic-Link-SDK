# my_deeplink_sdk

A self-hosted Flutter SDK for handling **Deep Links** and **Deferred Deep Links** on Android and iOS.  
⚡ No third-party services required — built with pure Dart.

---

## ✨ Features
- 📱 Works with both Android & iOS
- 🔗 Easy setup for deep links and deferred deep links
- ⚡️ No third-party dependencies — pure Dart implementation
- 🧪 Built-in support for custom JSON payloads
- 🛠 Compatible with Flutter & Dart

---

## 📦 Installation

Add the SDK to your `pubspec.yaml` as a Git dependency:

```yaml
dependencies:
  my_deeplink_sdk:
    git:
      url: https://github.com/chiragjanjmeratecocraft/Flutter-Dynamic-Link-SDK.git
```

After updating `pubspec.yaml`, run the following commands in your project root:

```sh
flutter clean
flutter pub get
```

> `flutter clean` removes the old build cache. `flutter pub get` fetches the newly added dependency. Always run both after modifying `pubspec.yaml`.

---

## ⚡ Quick Start (60 seconds)

1) Add a custom scheme

- Android → add an `intent-filter` to `android/app/src/main/AndroidManifest.xml` under your main activity:
```xml
<intent-filter>
  <action android:name="android.intent.action.VIEW"/>
  <category android:name="android.intent.category.DEFAULT"/>
  <category android:name="android.intent.category.BROWSABLE"/>
  <data android:scheme="song" />
</intent-filter>
```

- iOS → add URL Schemes in `ios/Runner/Info.plist`:
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>song</string>
    </array>
  </dict>
</array>
```

2) Initialise the SDK

```dart
Future<void> _bootstrapSdk() async {
  await MyDeeplinkSdk.init({});
  await MyDeeplinkSdk.startSmartLinking(
    options: SmartLinkingOptions(
      onSuccess: _routeFromDeepLink,
    ),
  );
}
```

3) Handle the link

```dart
void _routeFromDeepLink(DynamicLinkData data) {
  if (!mounted) return;
  final payload = data.customData;
  // Write your navigation logic here based on the payload
}
```

4) Validate

- iOS: `xcrun simctl openurl booted "song://open/profile"`
- Android: `adb shell am start -W -a android.intent.action.VIEW -d "song://open/profile" com.yourapp.package`

For HTTPS Universal Links, see the full Setup section below.

---

## 🚀 Usage

### Using the _bootstrapSdk method

`_bootstrapSdk()` initialises the SDK and starts listening for both the initial URL and subsequent deep link events.

```dart
Future<void> _bootstrapSdk() async {
  await MyDeeplinkSdk.init({});
  await MyDeeplinkSdk.startSmartLinking(
    options: SmartLinkingOptions(
      onSuccess: _routeFromDeepLink,
    ),
  );
}
```

---

### Handling the Link Payload

`_routeFromDeepLink` receives a `DynamicLinkData` object and handles navigation. The logic inside will vary based on your app's screen structure — customise it accordingly:

```dart
void _routeFromDeepLink(DynamicLinkData data) {
  if (!mounted) return;

  final payload = data.customData;
  final screen = payload['screen']?.toString().trim().toLowerCase();

  if (screen == 'library' || payload['song_id'] != null) {
    final id = payload['song_id']?.toString() ?? 'UNKNOWN';
    print('Navigating to song: $id');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LibraryScreen(song_id: id),
      ),
    );
    return;
  }
}
```

> The payload keys (`screen`, `song_id`, etc.) are defined when you create the link in the Dynamic Link Tool.

---

## ✅ Validate your setup

Run these commands after building the app (replace `com.yourapp.package`):

- iOS (Simulator):
```sh
xcrun simctl openurl booted "song://open/profile"
```

- Android (Device/Emulator):
```sh
adb shell am start \
  -W -a android.intent.action.VIEW \
  -d "song://open/profile" \
  com.yourapp.package
```

If using HTTPS universal links, verify your hosted files:

- Android: `https://<your-domain>/.well-known/assetlinks.json`
- iOS: `https://<your-domain>/apple-app-site-association`

---

## ⚙️ Setup

### 🔹 Android (Schemes & App Links)

1. Open `android/app/src/main/AndroidManifest.xml` and add an intent filter inside your main `<activity>`.

Scheme-based (custom scheme like `song://`):
```xml
<intent-filter>
  <action android:name="android.intent.action.VIEW"/>
  <category android:name="android.intent.category.DEFAULT"/>
  <category android:name="android.intent.category.BROWSABLE"/>
  <data android:scheme="song" />
</intent-filter>

<intent-filter>
  <action android:name="android.intent.action.VIEW"/>
  <category android:name="android.intent.category.DEFAULT"/>
  <category android:name="android.intent.category.BROWSABLE"/>
  <data android:scheme="newSong"/>
</intent-filter>
```

App Links (HTTPS, verified):
```xml
<intent-filter android:autoVerify="true">
  <action android:name="android.intent.action.VIEW"/>
  <category android:name="android.intent.category.DEFAULT"/>
  <category android:name="android.intent.category.BROWSABLE"/>
  <data
    android:scheme="https"
    android:host="backend-dynamiclink.tecocraft.us"
    android:pathPrefix="/" />
</intent-filter>
```

2. Each scheme must have its own separate `intent-filter` block — do not combine multiple schemes in one filter.

3. Rebuild the Android app after any changes to `AndroidManifest.xml`.

### 🔹 iOS (Schemes & Universal Links)

1. Register your URL schemes in `ios/Runner/Info.plist` under `CFBundleURLSchemes` and `LSApplicationQueriesSchemes`:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLName</key>
    <string>com.tecocraft.sdk.my_deeplink_sdk_example</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>newSong</string>
      <string>song</string>
    </array>
  </dict>
</array>

<key>LSApplicationQueriesSchemes</key>
<array>
  <string>https</string>
  <string>http</string>
  <string>newSong</string>
  <string>song</string>
</array>
```

2. Rebuild the iOS app after any changes to `Info.plist`.

### 🔹 Flutter Flavors (Multiple Environments)

If your project uses **Flutter flavors** (e.g. `dev`, `staging`, `production`), each flavor typically has its own bundle ID and package name. You need to register schemes for each flavor separately.

**Android** — add an intent filter in the manifest file for each flavor. Flutter flavor manifests are usually located at:

```
android/app/src/<flavor>/AndroidManifest.xml
```

Example for a `production` flavor:
```xml
<intent-filter>
  <action android:name="android.intent.action.VIEW"/>
  <category android:name="android.intent.category.DEFAULT"/>
  <category android:name="android.intent.category.BROWSABLE"/>
  <data android:scheme="song" />
</intent-filter>
```

**iOS** — each flavor has its own `.xcconfig` and `Info.plist`. Add the URL schemes to the `Info.plist` for each flavor:
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>song</string>
      <string>newSong</string>
    </array>
  </dict>
</array>
```

> If you are not using flavors, you do not need this section. The standard Android and iOS setup above is sufficient.

---

## 🔗 Generating Links

Links are created and managed through the [Dynamic Link Tool](https://backend-dynamiclink.tecocraft.us) web interface.

1. Register and log in to your account.
2. Click **Add Project** and fill in your app details — package name, bundle ID, store URLs, and publication status.
3. Inside the project, go to **View Links → Add Link**.
4. Set the title, description, and URL schemes. The scheme values must exactly match what is configured in `AndroidManifest.xml` and `Info.plist`.
5. Add a **JSON Data** payload to control in-app navigation:

```json
{
  "extra": { "source": "deeplink" },
  "screen": "library",
  "song_id": 2
}
```

---

## 📖 API Reference

### `MyDeeplinkSdk.init(Map<String, dynamic> config)`
Initialises the SDK. Must be called before `startSmartLinking`.

### `MyDeeplinkSdk.startSmartLinking({ required SmartLinkingOptions options })`
Starts listening for incoming deep link events and calls the provided callbacks.

### `SmartLinkingOptions`

| Option | Type | Description |
|---|---|---|
| `onSuccess` | `Function(DynamicLinkData)` | Called when a deep link is successfully resolved |

### `DynamicLinkData`

| Field | Type | Description |
|---|---|---|
| `customData` | `Map<String, dynamic>` | The JSON payload defined when the link was created in the Dynamic Link Tool |

---

## 🧪 Testing

### Test Deep Links
The app must be installed on the device. Click the link — it should open the app and navigate to the correct screen.

### Test Deferred Deep Links
The app must be published on the App Store or Google Play Store. Click the link on a device where the app is not installed — it will redirect to the store, and after installation, navigate to the intended screen on first launch.

> If the app is not published, the SDK will return null as the response.

### Test Updated Logic Without Re-publishing

Once the app has been published at least once, you can test updated routing logic without submitting a new store release:

1. Implement the updated logic in your Flutter codebase.
2. Completely uninstall the app from your test device.
3. Click the dynamic link — the device will be redirected to the store page.
4. **Do not install from the store.** Instead, run the app directly from Android Studio or Xcode.
5. The SDK will pick up the deferred payload and your updated logic will execute.

> This bypass only works after the app has been published at least once.

---


---

## 📋 Requirements

- Flutter >= 3.0.0
- Dart >= 2.17.0
- iOS >= 12.0
- Android API Level >= 21

---

## 🤝 Contributing

Pull requests are welcome! For major changes, please open an issue first to discuss what you would like to change.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

MIT © [Tecocraft](https://github.com/tecocraft)

---

## 🛠️ Troubleshooting

- **Links not opening on Android**
    - Verify your `AndroidManifest.xml` intent-filters and ensure each scheme has its own separate filter block.
    - For App Links, confirm `assetlinks.json` is reachable and the SHA-256 fingerprints match your signing key.
    - Rebuild the app after any manifest changes.

- **Links not opening on iOS**
    - Confirm all URL schemes are listed in both `CFBundleURLSchemes` and `LSApplicationQueriesSchemes` in `Info.plist`.
    - For Universal Links, check the Associated Domains capability in Xcode and verify the AASA file is hosted over HTTPS with no redirects.
    - Rebuild the app after any `Info.plist` changes.

- **SDK returning null for deferred deep links**
    - Ensure the app is published on the App Store or Google Play Store. Deferred deep links do not work with unpublished apps.

---

## 🙋‍♀️ Support

- 📧 Email: support@tecocraft.com
- 🐛 Issues: [GitHub Issues](https://github.com/chiragjanjmeratecocraft/Flutter-Dynamic-Link-SDK/issues)
- 💬 Discussions: [GitHub Discussions](https://github.com/chiragjanjmeratecocraft/Flutter-Dynamic-Link-SDK/discussions)