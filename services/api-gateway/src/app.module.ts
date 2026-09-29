import { Module, NestModule, MiddlewareConsumer } from '@nestjs/common';
import { HttpModule } from '@nestjs/axios';
import * as fs from 'fs';
import { SessionGrid } from './security/session-grid';
import { AuthMiddleware } from './middleware/auth.middleware';
import { DynamicProxyMiddleware } from './middleware/dynamic-proxy.middleware';

@Module({
  imports: [HttpModule],
  providers: [
    {
      provide: SessionGrid,
      useFactory: async () => {
        const secretPath = '/secrets/jwt_shared_secret.txt';
        let jwtSecret = 'fallback-secret-key-32-bytes-min';
        if (fs.existsSync(secretPath)) {
          jwtSecret = fs.readFileSync(secretPath, 'utf8').trim();
        }
        const grid = new SessionGrid(
          process.env.VALKEY_HOST || 'localhost',
          process.env.VALKEY_PORT ? parseInt(process.env.VALKEY_PORT, 10) : 6379,
          jwtSecret
        );
        await grid.initialize().catch(console.error);
        return grid;
      }
    }
  ],
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer) {
    consumer
      // 🔐 Enforce sequential token authentication BEFORE executing dynamic reverse proxying
      .apply(AuthMiddleware, DynamicProxyMiddleware)
      .forRoutes('api/v1/*');
  }
}
