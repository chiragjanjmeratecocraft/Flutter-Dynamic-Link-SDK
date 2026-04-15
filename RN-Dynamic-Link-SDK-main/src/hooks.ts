import { useEffect } from 'react';
import type { ISmartLinkingOptions } from './types/common';
import { extractShortCode, fetchDynamicLink, trackPendingRedirect } from './utils';
import { Linking } from 'react-native';
import { STORAGE_KEYS } from './constants';
import { getData, storeData } from './storage';

export function useSmartLinking(options: ISmartLinkingOptions = {}) {

  useEffect(() => {
    (async () => {
      try {
        const isFirstInstall = await getData(STORAGE_KEYS.HAS_FIRST_INSTALL);
        if (isFirstInstall) return;

        // Call trackPendingRedirect on first install
        const data = await trackPendingRedirect();
        if (data && options.onSuccess) {
          options.onSuccess(data);
        }

        await storeData(STORAGE_KEYS.HAS_FIRST_INSTALL, 'true');
      } catch (err) {
        options.onError?.(err as Error);
      }
    })()
  }, [options]);

  useEffect(() => {
    async function handleUrl(url: string) {
      options.onUrl?.(url);
      const shortCode = extractShortCode(url);
      if (!shortCode) return;

      try {
        const data = await fetchDynamicLink(shortCode);
        if (data && options.onSuccess) options.onSuccess(data);
      } catch (err) {
        options.onError?.(err as Error);
      }
    }

    // Initial link
    Linking.getInitialURL().then((url) => {
      if (url) handleUrl(url);
    });

    // Subsequent links
    const sub = Linking.addEventListener('url', ({ url }) => {
      handleUrl(url);
    });

    return () => sub.remove();
  }, [options]);
}
