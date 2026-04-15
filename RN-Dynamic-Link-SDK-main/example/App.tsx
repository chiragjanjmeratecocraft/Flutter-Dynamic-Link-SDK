/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 *
 * @format
 */

import { useSmartLinking } from '@tecocraft/rn-deeplinking';
import { NewAppScreen } from '@react-native/new-app-screen';
import { StatusBar, StyleSheet, useColorScheme, View } from 'react-native';
import {
  SafeAreaProvider,
  useSafeAreaInsets,
} from 'react-native-safe-area-context';

function App() {
  const isDarkMode = useColorScheme() === 'dark';

  useSmartLinking({
    onUrl(url) {
      console.log('Received URL:', url);
    },
    onSuccess(data) {
      console.log('Deep link data:', data);
    },
    onFallback(url) {
      console.warn('No deep link matched for URL:', url);
    },
    onError(error) {
      console.error('Deep link error:', error);
    },
  });

  return (
    <SafeAreaProvider>
      <StatusBar barStyle={isDarkMode ? 'light-content' : 'dark-content'} />
      <AppContent />
    </SafeAreaProvider>
  );
}

function AppContent() {
  const safeAreaInsets = useSafeAreaInsets();

  return (
    <View style={styles.container}>
      <NewAppScreen
        templateFileName="App.tsx"
        safeAreaInsets={safeAreaInsets}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
});

export default App;
