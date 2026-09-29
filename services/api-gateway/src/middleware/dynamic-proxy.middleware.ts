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
    const sessionClaims = req['session'];
    
    // 🔗 Generic Context-Path Routing Parser
    // URL format: /api/v1/trade-gateway/order/submit
    const urlParts = req.originalUrl.split('?')[0].split('/');
    const targetService = urlParts[3]; // Isolates 'trade-gateway' cleanly from the namespace array
    
    if (!targetService) {
      throw new BadGatewayException('Unable to resolve targeted downstream container identifier');
    }

    // Strip out the target service segment to pass the clean remaining URI downstream
    // Output format: /api/v1/order/submit
    const remainingUri = '/' + urlParts.slice(1, 3).concat(urlParts.slice(4)).join('/');
    
    // 🔌 Dynamically resolve internal port configurations via environment variables
    const envPortKey = `${targetService.toUpperCase().replace(/-/g, '_')}_PORT`;
    const internalPort = process.env[envPortKey] || '8080';
    
    const downstreamUrl = `http://${targetService}:${internalPort}${remainingUri}`;

    try {
      // 🚀 Streaming Reverse Proxy: Forward the request cleanly over the internal cluster mesh
      const responseStream = await firstValueFrom(
        this.httpService.request({
          method: req.method,
          url: downstreamUrl,
          data: req.body,
          headers: {
            ...req.headers,
            'X-User-Id': String(sessionClaims.sub_id), // Forward pre-verified identity context parameters
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
