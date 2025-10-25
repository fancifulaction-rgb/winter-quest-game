import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  base: '/winter-quest/',
  build: {
    outDir: 'dist',
    sourcemap: true
  },
  server: {
    host: true,
    port: 3000
  }
})