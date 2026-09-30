// ============================================================================
// FINARK PLATFORM - EDGE GATEWAY SECURITY GRID TEST MODULE (VITEST EDITION)
// Target File: services/api-gateway/src/security/session-grid.spec.ts
// BRS Mapping: BR-14 Automated Mock Testing Validation
// ============================================================================

import { describe, beforeEach, it, expect, vi } from 'vitest';
import { SessionGrid } from './session-grid.js';
import { Valkey } from 'iovalkey';

// 🔌 Global trackers to retain assertions visibility across class instances
const mockOnce = vi.fn().mockImplementation((event: string, callback: () => void) => {
  if (event === 'ready') {
    callback();
  }
});
const mockSetex = vi.fn();
const mockGet = vi.fn();
const mockDel = vi.fn();

// 🔐 Hardened: Use explicit class taxonomy to preserve the constructor prototype chain
vi.mock('iovalkey', () => {
  class MockValkey {
    public status = 'connecting';
    public once = mockOnce;
    public setex = mockSetex;
    public get = mockGet;
    public del = mockDel;
    
    constructor(config: any) {
      // iovalkey configuration absorption wrapper stub
    }
  }
  return { Valkey: MockValkey };
});

describe('SessionGrid TS SDK Test Suite via Vitest', () => {
  let sessionGrid: SessionGrid;
  let mockValkeyClient: any;
  const mockSecret = 'test-shared-cryptographic-secret-key-32-bytes';

  beforeEach(async () => {
    vi.clearAllMocks();
    
    sessionGrid = new SessionGrid('localhost', 6379, mockSecret);
    await sessionGrid.initialize();
    mockValkeyClient = (sessionGrid as any).cache;
  });

  it('should call setex with formatted key matching Python targets', async () => {
    mockSetex.mockResolvedValue('OK');
    
    const res = await sessionGrid.grant('t-1', 1, ['GUEST'], 60);
    
    expect(res).toBe(true);
    expect(mockValkeyClient.setex).toHaveBeenCalledWith('auth_session:t-1', 60, expect.any(String));
  });
});
