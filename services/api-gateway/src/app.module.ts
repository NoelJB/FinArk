// ============================================================================
// FINARK PLATFORM - EDGE MICROGATEWAY ROUTING APPLICATION ENGINE
// Target File: services/api-gateway/src/app.module.ts
// BRS Mapping: BR-01 / BR-05 Greenfield NestJS JwtModule Integration
// ============================================================================

import { Module, NestModule, MiddlewareConsumer } from '@nestjs/common';
import { HttpModule } from '@nestjs/axios';
import { JwtModule, JwtService } from '@nestjs/jwt';
import * as fs from 'fs';
import session from 'express-session'; // 🟢 FIXED: Import express-session wrapper
import { SessionGrid } from './security/session-grid.js';
import { AuthMiddleware } from './middleware/auth.middleware.js';
import { DynamicProxyMiddleware } from './middleware/dynamic-proxy.middleware.js';

// Extract the secure cryptographic key material out-of-band prior to initialization
const secretPath = '/run/secrets/jwt_shared_secret';

if (!fs.existsSync(secretPath)) {
  console.error(`❌ [api-gateway FATAL] OWASP Violation Protected: Secure secret file is missing at ${secretPath}. Aborting container execution.`);
  process.exit(1); // ◀ FAIL-FAST: Prevents insecure container execution loops
}

const jwtSecret = fs.readFileSync(secretPath, 'utf8').trim();

// 🔬 TELEMETRY GAUGING CHECKPOINT
console.log(`🔬 [api-gateway CHECKPOINT] Secret verification successful. Length: ${jwtSecret.length}, Slice: "${jwtSecret.substring(0, 4)}...${jwtSecret.substring(jwtSecret.length - 4)}"`);

@Module({
  imports: [
    HttpModule,
    JwtModule.register({
      global: true,
      secret: jwtSecret,
      verifyOptions: {
        algorithms: ['HS256'],
        clockTolerance: 5,
      },
    }),
  ],
  providers: [
    {
      provide: SessionGrid,
      inject: [JwtService],
      useFactory: async (jwtService: JwtService) => {
        const grid = new SessionGrid(
          process.env.VALKEY_HOST || 'localhost',
          process.env.VALKEY_PORT ? parseInt(process.env.VALKEY_PORT, 10) : 6379,
          jwtService,
        );
        await grid.initialize().catch(console.error);
        return grid;
      },
    },
  ],
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer) {
    // 🟢 FIXED BEST PRACTICE: Split the middleware applications into sequential, standalone blocks.
    // This allows express-session to fully initialize and pass control cleanly
    // down-line via internal execution chains before custom canopies engage.
    consumer
      .apply(
        session({
          secret: jwtSecret,
          resave: false,
          saveUninitialized: false,
          cookie: { secure: false },
        })
      )
      .forRoutes('*path'); // 🟢 FIXED: Captures multi-segment trajectories across modern NestJS engines natively

    // 🔐 Now these can execute down-line with full access to req.session properties
    consumer
      .apply(AuthMiddleware, DynamicProxyMiddleware)
      .forRoutes('*path'); // 🟢 FIXED: Captures multi-segment trajectories across modern NestJS engines natively
  }
}
