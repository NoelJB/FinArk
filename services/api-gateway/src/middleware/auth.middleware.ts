// ============================================================================
// FINARK PLATFORM - EDGE MICROGATEWAY PERIMETER AUTHENTICATION GATE
// Target File: services/api-gateway/src/middleware/auth.middleware.ts
// BRS Mapping: BR-01 Perimeter Security Gate
// ============================================================================

import { Injectable, NestMiddleware, UnauthorizedException } from '@nestjs/common';
import { Request, Response, NextFunction } from 'express';
import { SessionGrid } from '../security/session-grid';

@Injectable()
export class AuthMiddleware implements NestMiddleware {
  constructor(private readonly sessionGrid: SessionGrid) {}

  async use(req: Request, res: Response, next: NextFunction) {
    const authHeader = req.headers.authorization;
    if (!authHeader) {
      throw new UnauthorizedException('Missing perimeter security credentials');
    }

    const [schema, token] = authHeader.split(' ');
    if (!schema || schema.toLowerCase() !== 'bearer' || !token) {
      throw new UnauthorizedException('Malformed authorization context scheme');
    }

    // 🧪 white-box verification pass against the Valkey state grid memory
    const sessionClaims = await this.sessionGrid.isValid(token);
    if (!sessionClaims) {
      throw new UnauthorizedException('Token has expired or been administratively revoked');
    }

    // Attach the pre-verified claims directly to the request envelope for downstream use
    req['session'] = sessionClaims;
    next();
  }
}
