import * as admin from 'firebase-admin';
import { env } from './env';

let firebaseAdminApp: admin.app.App | null = null;
let isFirebaseInitialized = false;

if (env.FIREBASE_PROJECT_ID && env.FIREBASE_CLIENT_EMAIL && env.FIREBASE_PRIVATE_KEY) {
  try {
    firebaseAdminApp = admin.initializeApp({
      credential: admin.credential.cert({
        projectId: env.FIREBASE_PROJECT_ID,
        clientEmail: env.FIREBASE_CLIENT_EMAIL,
        privateKey: env.FIREBASE_PRIVATE_KEY,
      }),
    });
    isFirebaseInitialized = true;
    console.log('🔥 Firebase Admin SDK initialized successfully.');
  } catch (error) {
    console.warn('⚠️ Firebase Admin SDK initialization failed. Fallback dev mode active.', error);
  }
} else {
  console.log('ℹ️ Firebase credentials not provided in .env. Running Firebase Auth in Dev/Mock mode.');
}

export { firebaseAdminApp, isFirebaseInitialized, admin };
