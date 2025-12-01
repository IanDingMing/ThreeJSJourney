import { defineConfig } from 'vite'
import path from 'path'
import vue from '@vitejs/plugin-vue'
import glsl from 'vite-plugin-glsl';

// https://vite.dev/config/
export default defineConfig(({ mode }) => {
  const isProduction = mode === 'production';

  return {
    base: isProduction ? '/ThreeJSJourney/' : '/',
    plugins: [vue(), glsl()],
    resolve: {
      alias: {
        '@': path.resolve(__dirname, 'src'),
      }
    }
  }
})
