// ============================================================================
// FINARK PLATFORM - EDGE MICROGATEWAY GENERIC REVERSE PROXY MIDDLEWARE
// Target File: services/api-gateway/src/middleware/dynamic-proxy.middleware.ts
// BRS Mapping: BR-05 Universal Integration Router
// ============================================================================

import { Injectable, NestMiddleware, BadGatewayException } from '@nestjs/common';
import { Request, Response, NextFunction } from 'express';
import { HttpService } from '@nestjs/axios';
import { firstValueFrom } from 'rxjs';

@Injectable()
export class DynamicProxyMiddleware implements NestMiddleware {
  constructor(private readonly httpService: HttpService) {}

  async use(req: Request, res: Response, next: NextFunction) {
    const session = req.session;
    if (!session || !session.sub_id) {
      throw new BadGatewayException('Perimeter authentication security payload lost in context');
    }
    
    // 🔍 Hardened: Corrected string splitting sequence to isolate context path elements safely
    const cleanUrl = req.originalUrl.split('?')[0];
    const urlParts = cleanUrl.split('/');
    const targetService = urlParts[3]; 
    
    if (!targetService) {
      throw new BadGatewayException('Unable to resolve targeted downstream container identifier');
    }

    const remainingUri = '/' + urlParts.slice(1, 3).concat(urlParts.slice(4)).join('/');
    
    const envPortKey = `${targetService.toUpperCase().replace(/-/g, '_')}_PORT`;
    const internalPort = process.env[envPortKey] || '8080';
    
    const downstreamUrl = `http://${targetService}:${internalPort}${remainingUri}`;

    try {
      const responseStream = await firstValueFrom(
        this.httpService.request({
          method: req.method,
          url: downstreamUrl,
          data: req.body,
          headers: {
            ...req.headers,
            'X-User-Id': String(session.sub_id),
          },
        })
      );
      return res.status(responseStream.status).json(responseStream.data);
    } catch (error: any) {
      if (error.response) {
        return res.status(error.response.status).json(error.response.data);
      }
      return res.status(502).json({ error: `Downstream microservice '${targetService}' currently unreachable over port ${internalPort}` });
    }
  }
}
