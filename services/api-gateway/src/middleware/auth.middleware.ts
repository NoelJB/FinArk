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
    // 🌐 Hardened: Allow standard OPTIONS requests to pass through the authentication perimeter
    // This allows the single-origin microgateway to handle routing metrics seamlessly
    if (req.method === 'OPTIONS') {
      return next();
    }

    const authHeader = req.headers.authorization;
    if (!authHeader) {
      throw new UnauthorizedException('Missing perimeter security credentials');
    }

    const [schema, token] = authHeader.split(' ');
    if (!schema || schema.toLowerCase() !== 'bearer' || !token) {
      throw new UnauthorizedException('Malformed authorization context scheme');
    }

    const sessionClaims = await this.sessionGrid.isValid(token);
    if (!sessionClaims) {
      throw new UnauthorizedException('Token has expired or been administratively revoked');
    }

    // Clean property modification allowed natively by express-session type merging!
    req.session.sub_id = sessionClaims.sub_id;
    req.session.roles = sessionClaims.roles;
    next();
  }
}
