import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [vue()],
  server: {
    proxy: {
      '/api': {
        target: `http://localhost:${process.env.BACKEND_PORT || 8001}`,
        changeOrigin: true,
      },
    },
  },
})
