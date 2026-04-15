import { Platform } from 'react-native';
import { API_ROUTES, BASE_URL, TIMEOUT_DURATION } from './constants';
import { IDynamicLinkResponse } from './types/common';
import {
  getApplicationName,
  getBundleId,
  getManufacturerSync,
  getModel,
  getReadableVersion,
  getSystemVersion
} from 'react-native-device-info';

const customUserAgent = `(${getApplicationName()}/${getReadableVersion()}) (${getManufacturerSync()} ${getModel()}; ${Platform.OS} ${getSystemVersion()})`;

export async function fetchDynamicLink(
  shortCode: string
): Promise<IDynamicLinkResponse> {
  const controller = new AbortController();
  const id = setTimeout(() => controller.abort(), TIMEOUT_DURATION);

  try {
    const response = await fetch(`${BASE_URL.concat(API_ROUTES.GET_DETAILS)}/${encodeURIComponent(shortCode)}`, {
      signal: controller.signal
    });
    if (!response.ok) throw new Error(`API Error: ${response.status}`);
    const { data } = await response.json();
    return data;
  } finally {
    clearTimeout(id);
  }
}

export async function trackPendingRedirect(): Promise<IDynamicLinkResponse> {

  const controller = new AbortController();
  const id = setTimeout(() => controller.abort(), TIMEOUT_DURATION);

  try {
    const response = await fetch(`${BASE_URL.concat(API_ROUTES.PENDING_REDIRECT)}`, {
      signal: controller.signal,
      headers: { 'User-Agent': customUserAgent },
      body: JSON.stringify({ app_id: getBundleId(), device_type: Platform.OS.toUpperCase() })
    });
    if (!response.ok) throw new Error(`API Error: ${response.status}`);
    const { data } = await response.json();
    return data;
  } finally {
    clearTimeout(id);
  }
}

export function extractShortCode(url: string): string | null {
  try {
    // Extract the query string part
    const queryIndex = url.indexOf('?');
    if (queryIndex === -1) return null;

    const queryString = url.substring(queryIndex + 1);
    const params = queryString.split('&');

    for (const param of params) {
      const [key, value] = param.split('=');
      if (key === 'short_code') return value || null;
    }

    return null;
  } catch {
    return null;
  }
}
