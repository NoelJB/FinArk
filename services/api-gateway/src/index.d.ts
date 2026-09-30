// ============================================================================
// FINARK PLATFORM - EDGE MICROGATEWAY SESSION CUSTOM DEFINITIONS
// Target File: services/api-gateway/src/index.d.ts
// BRS Mapping: BR-01 Perimeter Security Type Canopy
// ============================================================================

import 'express-session';

declare global {
  namespace Express {
    interface Request {
      session: import('express-session').Session & import('express-session').SessionData;
    }
  }
}

declare module 'express-session' {
  interface SessionData {
    sub_id: number;
    roles: string[];
  }
}

export {};
