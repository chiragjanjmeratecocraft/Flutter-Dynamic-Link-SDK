import AsyncStorage from "@react-native-async-storage/async-storage";

/**
 * Retrieves string data from storage
 * @param key The key to retrieve
 * @returns Promise with string or undefined if not found/error
 */
export async function getData(key: string): Promise<string | undefined> {
    try {
        const value = await AsyncStorage.getItem(key);
        return value ?? undefined;
    } catch (error) {
        return undefined;
    }
}

/**
 * Stores data in storage
 * @param key The key to store
 * @param value The value to store (will be converted to string if not already)
 * @returns Promise<boolean> indicating success
 */
export async function storeData(key: string, value: any): Promise<boolean> {
    try {
        const stringValue = typeof value === 'string' ? value : JSON.stringify(value);
        await AsyncStorage.setItem(key, stringValue);
        return true;
    } catch (error) {
        return false;
    }
}

/**
 * Removes an item from storage
 * @param key The key to remove
 * @returns Promise<boolean> indicating success
 */
export async function removeStore(key: string): Promise<boolean> {
    try {
        await AsyncStorage.removeItem(key);
        return true;
    } catch (error) {
        return false;
    }
}

/**
 * Clears all data from storage
 */
export async function clearStorage(): Promise<void> {
    try {
        await AsyncStorage.clear();
    } catch (error) {
        // Silent error
    }
}
