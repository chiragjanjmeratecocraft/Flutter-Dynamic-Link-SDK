# @tecocraft/rn-deeplinking

A lightweight React Native library for handling **Deep Links** and **Universal Links**.  
⚡ No native code required — built with pure TypeScript.

---

## ✨ Features
- 📱 Works with both Android & iOS  
- 🔗 Easy setup for deep links and universal links  
- ⚡️ No native modules — pure JS/TS implementation  
- 🧪 Built-in TypeScript support  
- 🛠 Compatible with Expo & React Native CLI  

---

## 📦 Installation

```sh
# with npm
npm install @tecocraft/rn-deeplinking

# with yarn
yarn add @tecocraft/rn-deeplinking

# with pnpm
pnpm add @tecocraft/rn-deeplinking
```

---

## ⚡ Quick Start (60 seconds)

1) Add a custom scheme

- Android → add an intent-filter to `android/app/src/main/AndroidManifest.xml` under your main activity:
```xml
<intent-filter>
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="myapp" android:host="open" />
</intent-filter>
```

- iOS → add URL Schemes in `ios/YourApp/Info.plist`:
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>myapp</string>
    </array>
  </dict>
</array>
```

2) Use the hook

```tsx
import { useSmartLinking } from '@tecocraft/rn-deeplinking';

export default function App() {
  useSmartLinking({
    onUrl: (url) => console.log('URL:', url),
    onSuccess: (data) => console.log('Resolved:', data),
  });
  return null;
}
```

<!-- Backend configuration helpers are internal and not part of the public API. -->

3) Validate

- iOS: `xcrun simctl openurl booted "myapp://open/profile"`
- Android: `adb shell am start -W -a android.intent.action.VIEW -d "myapp://open/profile" com.yourapp.package`

For HTTPS App/Universal Links, see the full Setup below and host the files from `docs/`.

---

## 🚀 Usage

### Using the useSmartLinking hook

`useSmartLinking()` listens to the initial URL and subsequent deep link events and provides convenient callbacks.

```tsx
import React from 'react';
import { View, Text } from 'react-native';
import { useSmartLinking } from '@tecocraft/rn-deeplinking';

export default function App() {
  useSmartLinking({
    onUrl: (url) => {
      console.log('URL received:', url);
    },
    onSuccess: (data) => {
      // `data` is a normalized dynamic link response
      console.log('Resolved link:', data);
    },
    onFallback: (fallbackUrl) => {
      console.log('Will open fallback:', fallbackUrl);
    },
    onError: (err) => {
      console.warn('Deep link error:', err.message);
    },
  });

  return (
    <View>
      <Text>Deep Linking Example</Text>
    </View>
  );
}
```

<!-- Manual resolve utilities are internal; prefer the hook or Deeplink API. -->

---

### Prebuilt Deeplink API (event-based)

For a minimal, event-based API similar to React Native's `Linking`, use the `Deeplink` wrapper:

```tsx
import { Deeplink } from '@tecocraft/rn-deeplinking';
import { useEffect } from 'react';
import { View, Text } from 'react-native';

export default function App() {
  useEffect(() => {
    const unsubscribe = Deeplink.addListener((url) => {
      console.log('Opened via link:', url);
      // Handle your deep link logic here
    });

    return () => unsubscribe();
  }, []);

  return (
    <View>
      <Text>Deep Linking Example</Text>
    </View>
  );
}
```

You can also fetch the initial URL (if the app was launched from a link):

```ts
const initialUrl = await Deeplink.getInitialURL();
```

---

## ✅ Validate your setup

Run these commands after building the app (replace `com.yourapp.package`):

- iOS (Simulator):
```sh
xcrun simctl openurl booted "myapp://open/profile"
```

- Android (Device/Emulator):
```sh
adb shell am start \
  -W -a android.intent.action.VIEW \
  -d "myapp://open/profile" \
  com.yourapp.package
```

If using HTTPS links, verify your hosted files:

- Android: `https://<your-domain>/.well-known/assetlinks.json` (template: `docs/assetlinks.json`)
- iOS: `https://<your-domain>/apple-app-site-association` (template: `docs/apple-app-site-association`)

---

## ⚙️ Setup

### 🔹 Android (Schemes & App Links)

1. Open `android/app/src/main/AndroidManifest.xml` and add an intent filter inside your main `<activity>`.

Scheme-based (custom scheme like `myapp://open/...`):
```xml
<intent-filter android:autoVerify="false">
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="myapp" android:host="open" />
  <!-- Optional: pathPrefix or pathPattern -->
  <!-- <data android:scheme="myapp" android:host="open" android:pathPrefix="/product" /> -->
  
</intent-filter>
```

App Links (HTTPS, verified):
```xml
<intent-filter android:autoVerify="true">
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="https" android:host="links.example.com" />
</intent-filter>
```

2. If you enable App Links (`android:autoVerify="true"` with HTTPS):
   - Host `https://links.example.com/.well-known/assetlinks.json` with your app’s SHA-256 signature.
   - Example `assetlinks.json`:
   ```json
   [
     {
       "relation": ["delegate_permission/common.handle_all_urls"],
       "target": {
         "namespace": "android_app",
         "package_name": "com.yourapp",
         "sha256_cert_fingerprints": [
           "AA:BB:CC:...:ZZ"
         ]
       }
     }
   ]
   ```
   - Get the fingerprint with:
     ```sh
     keytool -list -v -keystore android/app/debug.keystore -alias androiddebugkey -storepass android -keypass android
     ```

3. Rebuild the Android app after changes to `AndroidManifest.xml`.

### 🔹 iOS (Schemes & Universal Links)

1. URL Schemes in `ios/YourApp/Info.plist`:
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLName</key>
    <string>myapp.deeplink</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>myapp</string>
    </array>
  </dict>
  <!-- Add more schemes if needed -->
</array>
```

2. AppDelegate (Objective‑C) `ios/YourApp/AppDelegate.m`:
```objc
#import <React/RCTLinkingManager.h>

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options
{
  return [RCTLinkingManager application:application openURL:url options:options];
}

// Universal Links (iOS 9+)
- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray * _Nullable))restorationHandler
{
  return [RCTLinkingManager application:application continueUserActivity:userActivity restorationHandler:restorationHandler];
}
```

AppDelegate (Swift) `ios/YourApp/AppDelegate.swift`:
```swift
import RCTLinking

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    return RCTLinkingManager.application(app, open: url, options: options)
  }

  func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
    return RCTLinkingManager.application(application, continue: userActivity, restorationHandler: restorationHandler)
  }
}
```

3. SceneDelegate (iOS 13+) if your project uses scenes (`SceneDelegate.swift/.m`):
```swift
func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
  guard let url = URLContexts.first?.url else { return }
  RCTLinkingManager.application(UIApplication.shared, open: url, options: [:])
}
```

4. Universal Links (Associated Domains):
   - In Xcode, enable Signing & Capabilities → add **Associated Domains**.
   - Add: `applinks:links.example.com`
   - Host `https://links.example.com/apple-app-site-association` (AASA) with your app ID and paths.
   - Rebuild the iOS app after capability changes.

### 🔹 Expo

If you're using Expo, add this to your `app.json`:

```json
{
  "expo": {
    "scheme": "myapp"
  }
}
```

For App Links/Universal Links with Expo, also configure:
```json
{
  "expo": {
    "ios": {
      "associatedDomains": ["applinks:links.example.com"]
    },
    "android": {
      "intentFilters": [
        {
          "action": "VIEW",
          "autoVerify": true,
          "data": [{ "scheme": "https", "host": "links.example.com" }],
          "category": ["BROWSABLE", "DEFAULT"]
        }
      ]
    }
  }
}
```

---

## 📖 API Reference (Public)

### Exports

- `useSmartLinking(options?: ISmartLinkingOptions): void`
  - Subscribes to initial and subsequent deep link events using React Native `Linking`.
  - Options:
    - `onUrl?: (url: string) => void`
    - `onSuccess?: (data: IDynamicLinkResponse) => void`
    - `onFallback?: (url: string) => void`
    - `onError?: (err: Error) => void`

<!-- Internal utils/constants are intentionally not documented in the public API. -->

### Types

- `IDynamicLinkResponse`
  - `{ title, description, longUrl, androidFallbackUrl, iosFallbackUrl, desktopFallbackUrl, customParams, customDomain, shortCode }`

- `ISmartLinkingOptions`
  - `{ onUrl?, onSuccess?, onFallback?, onError? }`

<!-- Internal types (for utils) are intentionally not documented. -->

---

## 🧭 React Navigation example

```tsx
import React, { useMemo } from 'react';
import { NavigationContainer, useNavigation } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { useSmartLinking } from '@tecocraft/rn-deeplinking';

const Stack = createNativeStackNavigator();

function Root() {
  const navigation = useNavigation();

  useSmartLinking({
    onSuccess: (data) => {
      // Example: route like myapp://open/product/123
      const path = data.longUrl || '';
      if (path.includes('/product/')) {
        const id = path.split('/product/')[1];
        navigation.navigate('Product', { id });
      }
    },
  });

  return null;
}

export default function App() {
  return (
    <NavigationContainer>
      <Stack.Navigator>
        <Stack.Screen name="Root" component={Root} />
        <Stack.Screen name="Product" component={() => null} />
      </Stack.Navigator>
    </NavigationContainer>
  );
}
```

---

## 📂 Templates

- Android App Links: `docs/assetlinks.json`
- iOS Universal Links: `docs/apple-app-site-association`

Copy, edit placeholders, and host them on your domain as described in Setup.


---

## 🧪 Testing Deep Links

### Test on iOS Simulator
```sh
xcrun simctl openurl booted "myapp://open/profile"
```

### Test on Android
```sh
adb shell am start \
  -W -a android.intent.action.VIEW \
  -d "myapp://open/profile" \
  com.yourapp.package
```

### Test on Device
Create test links in Notes app or send via message/email and tap them.

---

## 🧑‍💻 Example Project

This repo includes an `example/` React Native app that demonstrates deep linking setup.
Run it locally:

```sh
cd example
yarn install
yarn ios   # or yarn android
```

---

## 📋 Requirements

- React Native >= 0.60
- iOS >= 9.0
- Android API Level >= 16

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

- **TS2307 Cannot find module '@tecocraft/rn-deeplinking'**
  - Ensure the package version is installed and `node_modules/@tecocraft/rn-deeplinking/lib/index.d.ts` exists.
  - If using a local path, run `yarn build` inside the library so `lib/` is generated.
  - Restart your TS server/IDE and Metro: `yarn start --reset-cache`.

- **Links not opening on Android**
  - Verify your `AndroidManifest.xml` intent-filters and that the activity is not exported incorrectly.
  - For App Links, confirm `assetlinks.json` is reachable and fingerprints match the signing key.

- **Links not opening on iOS**
  - Confirm URL schemes exist in `Info.plist` and AppDelegate/SceneDelegate methods are present.
  - For Universal Links, check `Associated Domains` capability and AASA file validity over HTTPS (no redirects).

---

## 🙋‍♀️ Support

- 📧 Email: support@tecocraft.com
- 🐛 Issues: [GitHub Issues](https://github.com/chiragjanjmeratecocraft/RN-Dynamic-Link-SDK/issues)
- 💬 Discussions: [GitHub Discussions](https://github.com/chiragjanjmeratecocraft/RN-Dynamic-Link-SDK/discussions)