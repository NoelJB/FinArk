// ============================================================================
// FINARK PLATFORM - EDGE MICROGATEWAY VITEST E2E CONFIGURATION
// Target File: services/api-gateway/vitest.config.e2e.ts
// BRS Mapping: BR-14 High-Velocity Perimeter Testing Loops
// ============================================================================

import swc from 'unplugin-swc';
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    include: ['./test/**/*.e2e-spec.ts'],
    restoreMocks: true,
    clearMocks: true,
    fileParallelism: false, // Enforce strict chronological order over E2E passes
  },
  plugins: [
    swc.vite({
      module: { type: 'es6' },
      jsc: {
        parser: {
          syntax: 'typescript',
          decorators: true,
        },
        transform: {
          legacyDecorator: true,
          decoratorMetadata: true,
        },
      },
    }),
  ],
});
