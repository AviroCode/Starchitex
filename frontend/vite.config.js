import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// Proxy makes fetch('/api/...') same-origin in dev — sidesteps the
// backend's missing CORS config (see FRONTEND_GUIDE.md §7).
export default defineConfig({
  plugins: [react()],
  server: {
    port: 3000,
    proxy: { '/api': 'http://localhost:8080' },
  },
})
