import { Valkey } from 'iovalkey';
import * as jwt from 'jsonwebtoken';

export class SessionGrid {
  private cache: Valkey;

  constructor(
    private valkeyHost: string,
    private valkeyPort: number,
    private jwtSecret: string,
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
      const envelope = { sub_id: subjectId, roles, metadata: {} };
      // 🔐 Hardened: Aligned string keyspace tokens with the core Python SDK definitions
      const cacheKey = `auth_session:${tokenUuid}`;
      
      await this.cache.setex(cacheKey, ttlSeconds, JSON.stringify(envelope));
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
      
      // 🔐 Hardened: Aligned string keyspace tokens with the core Python SDK definitions
      const cacheKey = `auth_session:${tokenUuid}`;
      const rawSession = await this.cache.get(cacheKey);
      if (!rawSession) return null;
      
      return JSON.parse(rawSession);
    } catch {
      return null;
    }
  }

  async revoke(tokenUuid: string): Promise<boolean> {
    try {
      // 🔐 Hardened: Aligned string keyspace tokens with the core Python SDK definitions
      const cacheKey = `auth_session:${tokenUuid}`;
      await this.cache.del(cacheKey);
      return true;
    } catch {
      return false;
    }
  }
}
