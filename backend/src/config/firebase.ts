import * as admin from 'firebase-admin';
import { env } from './env';

let firebaseAdminApp: admin.app.App | null = null;
let isFirebaseInitialized = false;

const hasValidCredentials = Boolean(
  env.FIREBASE_PROJECT_ID && env.FIREBASE_CLIENT_EMAIL && env.FIREBASE_PRIVATE_KEY &&
  !env.FIREBASE_PRIVATE_KEY.includes('YOUR_PRIVATE_KEY_HERE')
);

if (hasValidCredentials) {
  try {
    firebaseAdminApp = admin.initializeApp({
      credential: admin.credential.cert({
        projectId: env.FIREBASE_PROJECT_ID,
        clientEmail: env.FIREBASE_CLIENT_EMAIL,
        privateKey: env.FIREBASE_PRIVATE_KEY,
      }),
    });
    isFirebaseInitialized = true;
    console.log('Firebase Admin SDK initialized successfully.');
  } catch (error: any) {
    console.warn('Firebase Admin SDK initialization failed:', error.message);
  }
} else {
  console.warn('Firebase Admin credentials are not configured. Authenticated routes will return 503.');
}

export { firebaseAdminApp, isFirebaseInitialized, admin };
