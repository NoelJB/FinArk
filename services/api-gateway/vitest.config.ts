// ============================================================================
// FINARK PLATFORM - EDGE MICROGATEWAY VITEST UNIT CONFIGURATION
// Target File: services/api-gateway/vitest.config.ts
// BRS Mapping: BR-14 High-Velocity Rust SWC Compiler Mesh
// ============================================================================

import swc from 'unplugin-swc';
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: true, // Native globals support maps standard describe/it blocks cleanly
    root: './src',
    environment: 'node',
    include: ['**/*.spec.ts'],
    restoreMocks: true,
    clearMocks: true,
  },
  plugins: [
    // Direct NestJS decorator support via optimized SWC bindings
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
