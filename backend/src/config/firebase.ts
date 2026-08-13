import * as admin from 'firebase-admin';
import { env } from './env';

let firebaseAdminApp: admin.app.App | null = null;
let isFirebaseInitialized = false;

const hasValidCredentials =
  env.FIREBASE_PROJECT_ID &&
  env.FIREBASE_CLIENT_EMAIL &&
  env.FIREBASE_PRIVATE_KEY &&
  !env.FIREBASE_PRIVATE_KEY.includes('YOUR_PRIVATE_KEY_HERE');

if (hasValidCredentials) {
  try {
    const privateKey = env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n');
    firebaseAdminApp = admin.initializeApp({
      credential: admin.credential.cert({
        projectId: env.FIREBASE_PROJECT_ID,
        clientEmail: env.FIREBASE_CLIENT_EMAIL,
        privateKey,
      }),
    });
    isFirebaseInitialized = true;
    console.log('🔥 Firebase Admin SDK initialized successfully.');
  } catch (error: any) {
    console.warn('⚠️ Firebase Admin SDK initialization failed:', error.message);
    console.log('ℹ️ Fallback Dev/Mock Mode Active for Authentication.');
  }
} else {
  console.log('ℹ️ Firebase production credentials not set in .env. Running in Dev/Mock Mode.');
}

export { firebaseAdminApp, isFirebaseInitialized, admin };
