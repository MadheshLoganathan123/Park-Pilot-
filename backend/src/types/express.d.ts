import { UserRole } from './enums';

export interface AuthenticatedUser {
  id: string;
  firebaseUid: string;
  email: string;
  role: UserRole;
  name?: string;
}
export interface FirebaseUser {
  firebaseUid: string;
  email?: string;
  name?: string;
  profileImage?: string;
}

declare global {
  namespace Express {
    interface Request {
      user?: AuthenticatedUser;
      firebaseUser?: FirebaseUser;
    }
  }
}
