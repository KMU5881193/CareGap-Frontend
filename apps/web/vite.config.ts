import {defineConfig} from 'vitest/config';
import react from '@vitejs/plugin-react';
import tailwindcss from '@tailwindcss/vite';
import {VitePWA} from 'vite-plugin-pwa';
import {fileURLToPath} from 'node:url';
export default defineConfig({plugins:[react(),tailwindcss(),VitePWA({registerType:'prompt',injectRegister:false,manifest:{name:'CareGap',short_name:'CareGap',start_url:'/',display:'standalone',theme_color:'#0f766e',background_color:'#ffffff'},workbox:{globPatterns:['**/*.{js,css,html,svg,ico,png}'],navigateFallbackDenylist:[/^\/api/],runtimeCaching:[]}})],resolve:{alias:{'@':fileURLToPath(new URL('./src',import.meta.url))}},server:{port:5173,proxy:{'/api':'http://127.0.0.1:3002','/health':'http://127.0.0.1:3002'}},test:{environment:'jsdom',setupFiles:['./src/test/setup.ts'],include:['src/**/*.test.{ts,tsx}']}});
