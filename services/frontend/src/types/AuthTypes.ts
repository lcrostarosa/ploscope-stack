// Authentication related types

export type AuthUser = {
  id: string;
  email: string;
  username?: string;
  first_name?: string;
  last_name?: string;
  created_at?: string;
  profile_picture?: string | null;
  [key: string]: unknown;
} | null;

export type AuthContextValue = {
  user: AuthUser;
  isAuthenticated: boolean;
  loading: boolean;
  token: string | null;
  authError: string | null;
  login: (
    email: string,
    password: string
  ) => Promise<{ success: boolean; message?: string; error?: string }>;
  register: (userData: Record<string, unknown>) => Promise<{
    success: boolean;
    message?: string;
    error?: string;
    user?: NonNullable<AuthUser>;
  }>;
  logout: () => Promise<void>;
  logoutAll: () => Promise<void>;
  updateProfile: (
    profileData: Record<string, unknown>
  ) => Promise<{ success: boolean; message?: string; error?: string }>;
  changePassword: (
    currentPassword: string,
    newPassword: string
  ) => Promise<{ success: boolean; message?: string; error?: string }>;
  refreshUserData: () => Promise<void>;
  clearAuthError: () => void;
};

export type AuthResult = {
  success: boolean;
  message?: string;
  user?: AuthUser;
};

export type ProfileUpdateResult = {
  success: boolean;
  message?: string;
  user?: AuthUser;
};

export type PasswordChangeResult = {
  success: boolean;
  message?: string;
};

export type CurrentUserResult = {
  success: boolean;
  user?: AuthUser;
  message?: string;
};
