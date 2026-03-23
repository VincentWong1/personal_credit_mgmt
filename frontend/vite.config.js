import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [vue()],
  server: {
    host: true,
    allowedHosts: ['jacelyn-isographical-lashonda.ngrok-free.dev', 'localhost'],
    proxy: {
      '/api': {
        target: `http://localhost:${process.env.BACKEND_PORT || 8001}`,
        changeOrigin: true,
      },
    },
  },
})
