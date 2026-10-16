// ============================================================================
// FINARK PLATFORM - EDGE MICROGATEWAY GENERIC REVERSE PROXY MIDDLEWARE
// Target File: services/api-gateway/src/middleware/dynamic-proxy.middleware.ts
// BRS Mapping: BR-05 Universal Integration Router (IBM Context-Routing Style)
// ============================================================================

import { Injectable, NestMiddleware, BadGatewayException } from '@nestjs/common';
import { Request, Response, NextFunction } from 'express';
import { HttpService } from '@nestjs/axios';
import { firstValueFrom } from 'rxjs';
import * as http from 'http'; // 🟢 FIXED: Import native node http module

@Injectable()
export class DynamicProxyMiddleware implements NestMiddleware {
  constructor(private readonly httpService: HttpService) {}

  async use(req: Request, res: Response, next: NextFunction) {
    const session = req.session;
    if (!session || !session.sub) {
      throw new BadGatewayException('Perimeter authentication security payload lost in context');
    }
    
    const cleanUrl = req.originalUrl.split('?')[0];
    const urlParts = cleanUrl.split('/');
    
    // Explicitly target string element at index 1 following the leading slash
    const serviceToken = urlParts[1]; 
    if (!serviceToken || serviceToken.trim() === '') {
      throw new BadGatewayException('Unable to resolve targeted downstream container identifier');
    }
    
    const targetService = String(serviceToken).trim();

    // Slice from index 2 forward to pass the remaining versioned path intact
    const remainingUri = '/' + urlParts.slice(2).join('/');
    
    const envPortKey = `${targetService.toUpperCase().replace(/-/g, '_')}_PORT`;
    const internalPort = process.env[envPortKey] || '8080';
    
    const downstreamUrl = `http://${targetService}:${internalPort}${remainingUri}`;

    // Strip 'host' and 'content-length' context up-front to prevent body length mismatches
    const { host, 'content-length': contentLength, ...cleanHeaders } = req.headers;

    // 🔍 TELEMETRY DIAGNOSTIC MARKERS
    console.log(`🚀 [api-gateway/proxy-middleware] Intercepted path parts: ${JSON.stringify(urlParts)}`);
    console.log(`🚀 [api-gateway/proxy-middleware] Isolated service target: '${targetService}'`);
    console.log(`🚀 [api-gateway/proxy-middleware] Stripping 'host' header context to break proxy loops. Cleaned headers copy: ${JSON.stringify(cleanHeaders)}`);
    console.log(`🚀 [api-gateway/proxy-middleware] Forwarding incoming TCP payload straight to: ${req.method} ${downstreamUrl}`);
    const bodyString = JSON.stringify(req.body || {});
    console.log(`[api-gateway/proxy-middleware] Inbound Content-Length Header: ${contentLength}, Actual Re-Serialized Body Length: ${bodyString.length}`);

    try {
      const startTime = Date.now();
      
      // 🟢 STEP A: Capture the real, uncompromised request configuration object
      const requestConfig = {
        method: req.method,
        url: downstreamUrl,
        data: req.body, // The original embedded Javascript payload object
        httpAgent: new http.Agent({ keepAlive: true }),
        headers: {
          ...cleanHeaders,
          'X-User-Id': String(session.sub),
        },
      };

      // 🟢 STEP B: Convert the entire actual execution object to JSON for absolute telemetry visibility
      try {
        console.log(`======================================================`);
        console.log(`📡 [TELEMETRY/api-gateway] PRE-FLIGHT AUTHENTIC WIRE CONFIGURATION INTERCEPT:`);
        console.log(JSON.stringify(requestConfig, null, 2));
        console.log(`======================================================`);
      } catch (jsonErr: any) {
        console.log(`⚠️ [TELEMETRY/api-gateway] Object stringification dropped due to circular structures: ${jsonErr.message}`);
      }

      console.log(`🚀 [api-gateway/proxy-middleware] FORWARDING payload to downstream target: ${downstreamUrl}`);
      
      // 🟢 STEP C: Pass the original unaltered request configuration object straight into the streaming fabric
      const responseStream = await firstValueFrom(
        this.httpService.request(requestConfig)
      );
      
      console.log(`✅ [api-gateway/proxy-middleware] Downstream response RECEIVED (Took ${Date.now() - startTime}ms) -> Status: ${responseStream.status}`);
      return res.status(responseStream.status).json(responseStream.data);
    } catch (error: any) {
      // ... leave your existing catch block properties completely intact ...
      if (error.response) {
        console.log(`⚠️ [api-gateway/proxy-middleware] Downstream target returned application error status: ${error.response.status}`);
        return res.status(error.response.status).json(error.response.data);
      }
      console.log(`❌ Failure to route to ${downstreamUrl}: ${error.message || error}`);
      return res.status(502).json({ error: `Downstream microservice '${targetService}' currently unreachable over port ${internalPort}` });
    }
  }
}
