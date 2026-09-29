import { SessionGrid } from './session-grid';
import * as jwt from 'jsonwebtoken';

jest.mock('redis', () => ({
  createClient: jest.fn().mockImplementation(() => ({
    connect: jest.fn().mockResolvedValue(null),
    setEx: jest.fn(),
    get: jest.fn(),
    del: jest.fn(),
  })),
}));

describe('SessionGrid TS SDK Test Suite', () => {
  let sessionGrid: SessionGrid;
  let mockRedisClient: any;
  const mockSecret = 'test-shared-cryptographic-secret-key-32-bytes';

  beforeEach(async () => {
    sessionGrid = new SessionGrid('localhost', 6379, mockSecret);
    await sessionGrid.initialize();
    mockRedisClient = (sessionGrid as any).cache;
  });

  it('should call setEx with formatted key', async () => {
    mockRedisClient.setEx.mockResolvedValue('OK');
    const res = await sessionGrid.grant('t-1', 1, ['GUEST'], 60);
    expect(res).toBe(true);
    expect(mockRedisClient.setEx).toHaveBeenCalledWith('active_token:t-1', 60, expect.any(String));
  });
});
