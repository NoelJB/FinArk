// ============================================================================
// FINARK PLATFORM - EDGE MICROGATEWAY PERIMETER AUTHENTICATION GATE
// Target File: services/api-gateway/src/middleware/auth.middleware.ts
// BRS Mapping: BR-01 Perimeter Security Gate
// ============================================================================

import { Injectable, NestMiddleware, UnauthorizedException } from '@nestjs/common';
import { Request, Response, NextFunction } from 'express';
import { SessionGrid } from '../security/session-grid.js';

@Injectable()
export class AuthMiddleware implements NestMiddleware {
  constructor(private readonly sessionGrid: SessionGrid) {}

  async use(req: Request, res: Response, next: NextFunction) {
    // 🔍 TELEMETRY DIAGNOSTIC
    console.log(`📡 [api-gateway] Inbound request intercepted: ${req.method} ${req.originalUrl}`);

    // 🌐 Hardened: Allow standard OPTIONS requests to pass through the authentication perimeter
    // This allows the single-origin microgateway to handle routing metrics seamlessly
    if (req.method === 'OPTIONS') {
      console.log(`📡 [api-gateway] CORS Pre-flight passthrough triggered for method OPTIONS`);
      return next();
    }

    const authHeader = req.headers.authorization;
    if (!authHeader) {
      console.log(`❌ [api-gateway] Admission Denied: Missing Authorization Header`);
      throw new UnauthorizedException('Missing perimeter security credentials');
    }

    const [schema, token] = authHeader.split(' ');
    if (!schema || schema.toLowerCase() !== 'bearer' || !token) {
      console.log(`❌ [api-gateway] Admission Denied: Malformed token schema structure`);
      throw new UnauthorizedException('Malformed authorization context scheme');
    }

    const sessionClaims = await this.sessionGrid.isValid(token);
    if (!sessionClaims) {
      console.log(`❌ [api-gateway] Admission Denied: Token signature invalid, expired, or revoked`);
      throw new UnauthorizedException('Token has expired or been administratively revoked');
    }

    // 🟢 BEST PRACTICE: Dot-notation is fully supported now that index.d.ts is natively scoped.
    // Ensure the session structure is active before appending claims parameters.
    if (req.session) {
      req.session.sub = String(sessionClaims.sub);
      req.session.roles = sessionClaims.roles;
      // 🔍 TELEMETRY DIAGNOSTIC
      console.log(`✅ [api-gateway] Token verified successfully. Context mapped: sub=${req.session.sub}, roles=${JSON.stringify(req.session.roles)}`);
    } else {
      console.log(`❌ [api-gateway] Security Canopy Fault: express-session context unallocated`);
      throw new UnauthorizedException('Security Canopy Fault: express-session context unallocated on request stream');
    }

    next();
  }
}
