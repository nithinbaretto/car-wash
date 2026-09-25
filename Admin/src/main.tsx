import React from 'react';
import {createRoot} from 'react-dom/client';
import {BrowserRouter} from 'react-router-dom';
import {QueryClient, QueryClientProvider} from '@tanstack/react-query';
import {AppThemeProvider} from './context/ThemeContext';
import {ToastProvider} from './context/ToastContext';
import {AuthProvider} from './context/AuthContext';
import {App} from './App';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      refetchOnWindowFocus: true,
      retry: 1,
      staleTime: 30000,
    },
  },
});

const rootElement = document.getElementById('root');
if (!rootElement) {
  throw new Error('Root element not found in DOM.');
}

createRoot(rootElement).render(
  <React.StrictMode>
    <QueryClientProvider client={queryClient}>
      <AppThemeProvider>
        <ToastProvider>
          <AuthProvider>
            <BrowserRouter>
              <App />
            </BrowserRouter>
          </AuthProvider>
        </ToastProvider>
      </AppThemeProvider>
    </QueryClientProvider>
  </React.StrictMode>
);
