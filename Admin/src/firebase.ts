import {initializeApp} from 'firebase/app';
import {getAuth, setPersistence, browserSessionPersistence} from 'firebase/auth';

const config = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
  appId: import.meta.env.VITE_FIREBASE_APP_ID,
};
export const firebaseEnabled = Object.values(config).every(Boolean);
export const auth = firebaseEnabled ? getAuth(initializeApp(config)) : null;
export async function useSessionPersistence() { if (auth) await setPersistence(auth, browserSessionPersistence); }
