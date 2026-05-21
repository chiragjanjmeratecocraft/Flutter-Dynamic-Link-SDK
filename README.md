# Flutter Dynamic Link SDK

A self-hosted Flutter SDK for handling **deep links** and **deferred deep links** on Android and iOS. Built as a customisable alternative to Firebase Dynamic Links — giving you full control over linking logic, navigation, and analytics.

---

## How It Works

| Scenario | Behaviour |
|---|---|
| App is installed | Link opens the app and navigates directly to the intended screen |
| App is not installed | Link redirects to the App Store or Play Store, then navigates to the intended screen after install |

---

## Installation

Add the SDK to your `pubspec.yaml` as a Git dependency:

```yaml
dependencies:
  my_deeplink_sdk:
    git:
      url: https://github.com/chiragjanjmeratecocraft/Flutter-Dynamic-Link-SDK.git
```

---

## Platform Configuration

### Android

In `AndroidManifest.xml`, add a separate `intent-filter` for each URL scheme. Do not combine multiple schemes in one filter.

```xml
<!-- Custom scheme: song -->
<intent-filter>
    <action android:name="android.intent.action.VIEW"/>
    <category android:name="android.intent.category.DEFAULT"/>
    <category android:name="android.intent.category.BROWSABLE"/>
    <data android:scheme="song" />
</intent-filter>

<!-- Custom scheme: newSong -->
<intent-filter>
    <action android:name="android.intent.action.VIEW"/>
    <category android:name="android.intent.category.DEFAULT"/>
    <category android:name="android.intent.category.BROWSABLE"/>
    <data android:scheme="newSong"/>
</intent-filter>

<!-- HTTPS universal link with domain verification -->
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

### iOS

In `Info.plist`, register your schemes under `CFBundleURLSchemes` and `LSApplicationQueriesSchemes`:

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

---

## Usage

### 1. Initialise the SDK

Call `_bootstrapSdk` early in the flutter app lifecycle (e.g. from `initState`):

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

### 2. Handle the Link Payload

Implement `_routeFromDeepLink` to read the payload and navigate accordingly. Customise this logic to match your app's screen structure:

```dart
void _routeFromDeepLink(DynamicLinkData data) {
    if (!mounted) return;

    final payload = data.customData;
    final screen = payload['screen']?.toString().trim().toLowerCase();

    if (screen == 'library' || payload['song_id'] != null) {
        final id = payload['song_id']?.toString() ?? 'UNKNOWN';
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

## Generating Links

Links are created and managed through the [Dynamic Link Tool](https://dynamiclink.tecocraft.us/user/dashboard) web interface.

1. Register and log in to your account.
2. Click **Add Project** and fill in your app's details — package name, bundle ID, store URLs, and publication status.
3. Inside the project, go to **View Links → Add Link**.
4. Set the title, description, and URL schemes. Schemes must exactly match what is configured in `AndroidManifest.xml` and `Info.plist`.
5. Add a **JSON Data** payload to control in-app navigation:

```json
{
    "extra": { "source": "deeplink" },
    "screen": "library",
    "song_id": 2
}
```

---

## Testing

### Deep Links
The app must be installed on the device. Click the link — it should open the app and navigate to the correct screen.

### Deferred Deep Links
The app must be published on the App Store or Google Play Store. Click the link on a device without the app installed — it will redirect to the store, and after installation, navigate to the intended screen on first launch.

### Testing Updated Logic Without Re-publishing
After the app has been published at least once, you can test new routing logic without a store release:

1. Implement the updated logic in your codebase.
2. Completely uninstall the app from your test device.
3. Click the dynamic link — you will be redirected to the store page.
4. **Do not install from the store.** Instead, run the app directly from Android Studio or Xcode.
5. The SDK will pick up the deferred payload and your updated logic will execute.

> This bypass only works after the app has been published at least once.

---
