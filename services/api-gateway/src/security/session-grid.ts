import { createClient } from 'redis';
import * as jwt from 'jsonwebtoken';

export class SessionGrid {
  private cache: any;

  constructor(
    private valkeyHost: String,
    private valkeyPort: number,
    private jwtSecret: string,
  ) {
    this.cache = createClient({ url: `redis://${valkeyHost}:${valkeyPort}` });
  }

  async initialize(): Promise<void> {
    await this.cache.connect();
  }

  async grant(tokenUuid: string, subjectId: number, roles: string[], ttlSeconds: number): Promise<boolean> {
    try {
      const envelope = { sub_id: subjectId, roles, metadata: {} };
      const cacheKey = `active_token:${tokenUuid}`;
      await this.cache.setEx(cacheKey, ttlSeconds, JSON.stringify(envelope));
      return true;
    } catch {
      return false;
    }
  }

  async isValid(rawToken: string): Promise<any | null> {
    try {
      const payload: any = jwt.verify(rawToken, this.jwtSecret);
      const tokenUuid = payload.jti;
      if (!tokenUuid) return null;
      const cacheKey = `active_token:${tokenUuid}`;
      const rawSession = await this.cache.get(cacheKey);
      if (!rawSession) return null;
      return JSON.parse(rawSession);
    } catch {
      return null;
    }
  }

  async revoke(tokenUuid: string): Promise<boolean> {
    try {
      const cacheKey = `active_token:${tokenUuid}`;
      await this.cache.del(cacheKey);
      return true;
    } catch {
      return false;
    }
  }
}
