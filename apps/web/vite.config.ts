import {defineConfig} from 'vitest/config';
import react from '@vitejs/plugin-react';
import tailwindcss from '@tailwindcss/vite';
import {VitePWA} from 'vite-plugin-pwa';
import {fileURLToPath} from 'node:url';
import {loadEnv} from 'vite';
export default defineConfig(({mode}) => {
 const { BACKEND_URL } = loadEnv(mode, process.cwd(), '');
 if (BACKEND_URL) {
  const target = new URL(BACKEND_URL);
  if (!['http:', 'https:'].includes(target.protocol)) throw new Error('BACKEND_URL must be an HTTP(S) URL');
 }
 return {plugins:[react(),tailwindcss(),VitePWA({registerType:'prompt',injectRegister:false,manifest:{name:'CareGap',short_name:'CareGap',start_url:'/',display:'standalone',theme_color:'#0f766e',background_color:'#ffffff'},workbox:{globPatterns:['**/*.{js,css,html,svg,ico,png}'],navigateFallbackDenylist:[/^\/api/],runtimeCaching:[]}})],resolve:{alias:{'@':fileURLToPath(new URL('./src',import.meta.url))}},server:{proxy:BACKEND_URL ? {'/api':BACKEND_URL,'/health':BACKEND_URL} : undefined},test:{environment:'jsdom',setupFiles:['./src/test/setup.ts'],include:['src/**/*.test.{ts,tsx}']}};
});
