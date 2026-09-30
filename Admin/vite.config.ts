import {defineConfig, loadEnv} from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig(({mode}) => {
  const env = loadEnv(mode, '.', '');
  const target = env.API_PROXY_TARGET || (env.VITE_FIREBASE_PROJECT_ID
    ? `http://127.0.0.1:5002/${env.VITE_FIREBASE_PROJECT_ID}/asia-south1/api`
    : undefined);
  return {
    plugins: [react()],
    server: {proxy: target ? {'/v1': {target, changeOrigin: true}} : undefined},
    build: {outDir: '../Backend/admin-dist', emptyOutDir: true},
  };
});
