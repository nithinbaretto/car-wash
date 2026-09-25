import React, {createContext, useContext, useEffect, useState} from 'react';
import {onAuthStateChanged, signOut, User} from 'firebase/auth';
import {auth} from '../firebase';
import {AdminProfile} from '../types';

interface AuthContextType {
  user: User | null;
  adminProfile: AdminProfile | null;
  setAdminProfile: (profile: AdminProfile | null) => void;
  isDemo: boolean;
  loading: boolean;
  enableDemoMode: () => void;
  disableDemoMode: () => void;
  logout: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType>({
  user: null,
  adminProfile: null,
  setAdminProfile: () => {},
  isDemo: false,
  loading: true,
  enableDemoMode: () => {},
  disableDemoMode: () => {},
  logout: async () => {},
});

export const useAuth = () => useContext(AuthContext);

export const AuthProvider: React.FC<{children: React.ReactNode}> = ({children}) => {
  const [user, setUser] = useState<User | null>(null);
  const [adminProfile, setAdminProfile] = useState<AdminProfile | null>(null);
  const [loading, setLoading] = useState(true);
  const [isDemo, setIsDemo] = useState<boolean>(() => {
    return localStorage.getItem('cw_admin_demo_mode') === 'true';
  });

  useEffect(() => {
    if (isDemo) {
      setUser({
        uid: 'super_admin_demo',
        email: 'superadmin@cleanwheel.internal',
        displayName: 'Aayush Shah (Super Admin)',
      } as any);
      setAdminProfile({
        uid: 'super_admin_demo',
        email: 'superadmin@cleanwheel.internal',
        displayName: 'Aayush Shah (Super Admin)',
        permissions: ['super_admin'],
      });
      setLoading(false);
      return;
    }

    if (!auth) {
      setLoading(false);
      return;
    }

    const unsubscribe = onAuthStateChanged(auth, (firebaseUser) => {
      setUser(firebaseUser);
      setLoading(false);
    });

    return () => unsubscribe();
  }, [isDemo]);

  const enableDemoMode = () => {
    localStorage.setItem('cw_admin_demo_mode', 'true');
    setIsDemo(true);
  };

  const disableDemoMode = () => {
    localStorage.removeItem('cw_admin_demo_mode');
    setIsDemo(false);
    setUser(null);
    setAdminProfile(null);
  };

  const logout = async () => {
    if (isDemo) {
      disableDemoMode();
      return;
    }
    if (auth) {
      await signOut(auth);
    }
    setUser(null);
    setAdminProfile(null);
  };

  return (
    <AuthContext.Provider
      value={{
        user,
        adminProfile,
        setAdminProfile,
        isDemo,
        loading,
        enableDemoMode,
        disableDemoMode,
        logout,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};
