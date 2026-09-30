import React, {createContext, useContext, useEffect, useState} from 'react';
import {onAuthStateChanged, signOut, User} from 'firebase/auth';
import {useQueryClient} from '@tanstack/react-query';
import {auth} from '../firebase';
import {AdminProfile} from '../types';

interface AuthContextType {
  user: User | null;
  adminProfile: AdminProfile | null;
  setAdminProfile: (profile: AdminProfile | null) => void;
  loading: boolean;
  logout: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType>({user: null, adminProfile: null, setAdminProfile: () => {}, loading: true, logout: async () => {}});
export const useAuth = () => useContext(AuthContext);

export const AuthProvider: React.FC<{children: React.ReactNode}> = ({children}) => {
  const queryClient = useQueryClient();
  const [user, setUser] = useState<User | null>(null);
  const [adminProfile, setAdminProfile] = useState<AdminProfile | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!auth) { setLoading(false); return; }
    return onAuthStateChanged(auth, (firebaseUser) => {
      queryClient.clear();
      setAdminProfile(null);
      setUser(firebaseUser);
      setLoading(false);
    });
  }, [queryClient]);

  const logout = async () => {
    if (auth) await signOut(auth);
    queryClient.clear();
    setUser(null);
    setAdminProfile(null);
  };

  return <AuthContext.Provider value={{user, adminProfile, setAdminProfile, loading, logout}}>{children}</AuthContext.Provider>;
};
