// ============================================================================
// FINARK PLATFORM - EDGE MICROGATEWAY PERIMETER VITEST END-TO-END SUITE
// Target File: services/api-gateway/test/app.e2e-spec.ts
// BRS Mapping: BR-14 Automated Integration Validation Gates
// ============================================================================

import { describe, beforeAll, afterAll, it, expect } from 'vitest';
import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from './../src/app.module.js';

describe('NestJS API Microgateway Edge E2E Suite via Vitest 5', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  it('🔒 GET /api/v1/trade-gateway/order -> Should reject requests missing a Bearer token with 401', async () => {
    const response = await request(app.getHttpServer())
      .get('/api/v1/trade-gateway/order');
    expect(response.status).toBe(401);
  });

  it('🌐 OPTIONS /api/v1/trade-gateway/order -> Should allow unauthenticated requests to bypass the perimeter guard', async () => {
    const response = await request(app.getHttpServer())
      .options('/api/v1/trade-gateway/order')
      .set('Origin', 'http://localhost:4200');
    
    // The request successfully clears AuthMiddleware; it returns 502/404 because trade-gateway doesn't exist yet
    // This confirms the middleware perimeter didn't drop a 401 block on the request!
    expect(response.status).not.toBe(401);
  });

  it('🛑 GET /api/v1/trade-gateway/order -> Should reject an invalid token signature with 401', async () => {
    const response = await request(app.getHttpServer())
      .get('/api/v1/trade-gateway/order')
      .set('Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.invalid.signature');
    expect(response.status).toBe(401);
  });
});
