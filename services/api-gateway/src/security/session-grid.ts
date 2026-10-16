// ============================================================================
// FINARK PLATFORM - EDGE MICROGATEWAY IN-MEMORY CACHE SCHEMA (DIAGNOSTIC TIER)
// Target File: services/api-gateway/src/security/session-grid.ts
// BRS Mapping: BR-14 Greenfield Unified iovalkey Parameter Layout
// ============================================================================

import { Valkey } from 'iovalkey';
// 🟢 FIXED: Using NestJS's modern native JWT Service wrapper instead of 'jsonwebtoken'
import { JwtService } from '@nestjs/jwt';

export class SessionGrid {
  private cache: Valkey;

  constructor(
    private valkeyHost: string,
    private valkeyPort: number,
    // 🟢 FIXED: Inject or pass the JwtService instance
    private jwtService: JwtService,
  ) {
    this.cache = new Valkey({
      host: String(valkeyHost),
      port: valkeyPort,
      maxRetriesPerRequest: 3, 
    });
  }

  async initialize(): Promise<void> {
    if (this.cache.status !== 'ready') {
      await new Promise<void>((resolve, reject) => {
        this.cache.once('ready', () => resolve());
        this.cache.once('error', (err) => reject(err));
      });
    }
  }

  async grant(tokenUuid: string, subjectId: number, roles: string[], ttlSeconds: number): Promise<boolean> {
    try {
      const envelope = { sub: String(subjectId), roles, metadata: {} };
      const cacheKey = `auth_session:${tokenUuid}`;
      
      // iovalkey utilizes the standard unified .set() layout with 'EX' argument tokens
      await this.cache.set(cacheKey, JSON.stringify(envelope), 'EX', ttlSeconds);
      return true;
    } catch (grantFault: any) {
      console.error(`❌ [api-gateway TELEMETRY] Cache insertion failed: ${grantFault.message}`);
      return false;
    }
  }

  async isValid(rawToken: string): Promise<any | null> {
    const currentContainerTime = Math.floor(Date.now() / 1000);
    
    try {
      // 🟢 FIXED: Use modern JwtService verification with your existing parameters
      const payload: any = await this.jwtService.verifyAsync(rawToken, {
        algorithms: ['HS256'],
        clockTolerance: 5,
      });
      
      const tokenUuid = payload.jti;
      if (!tokenUuid || !payload.sub) return null;
      
      const cacheKey = `auth_session:${tokenUuid}`;
      const rawSession = await this.cache.get(cacheKey);
      
      if (!rawSession) {
        console.log(`⚠️ [api-gateway TELEMETRY] Cryptography passed but key absent in Valkey grid space: ${cacheKey}`);
        return null;
      }
      
      return JSON.parse(rawSession);
    } catch (verificationError: any) {
      console.log("======================================================");
      console.log("🚨 [api-gateway TELEMETRY] EDGE CANOPY VALIDATION FAILURE");
      console.log(`👉 Raw Exception Trace: ${verificationError.message}`);
      console.log(`👉 Current api-gateway Container Clock: ${currentContainerTime}`);
      
      // 🟢 FIXED: Use modern JwtService to decode unverified payload tokens safely
      const unverifiedPayload: any = this.jwtService.decode(rawToken);
      if (unverifiedPayload) {
        console.log(`👉 Embedded JWT 'jti' UUID: ${unverifiedPayload.jti}`);
        console.log(`👉 Embedded JWT 'iat' (Issued At): ${unverifiedPayload.iat} (Delta to current container clock: ${unverifiedPayload.iat - currentContainerTime}s)`);
        console.log(`👉 Embedded JWT 'exp' (Expiration): ${unverifiedPayload.exp} (Remaining duration: ${unverifiedPayload.exp - currentContainerTime}s)`);
      } else {
        console.log("❌ Telemetry Alert: Token structural layout is fully unparseable base64 string bytes.");
      }
      console.log("======================================================");
      return null;
    }
  }

  async revoke(tokenUuid: string): Promise<boolean> {
    try {
      const cacheKey = `auth_session:${tokenUuid}`;
      await this.cache.del(cacheKey);
      return true;
    } catch (revokeFault: any) {
      console.error(`❌ [api-gateway TELEMETRY] Cache eviction dropped command: ${revokeFault.message}`);
      return false;
    }
  }
}
