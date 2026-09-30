// ============================================================================
// FINARK CORE PLATFORM CHASSIS SDK - JAVA DISTRIBUTED SECURITY GRID
// Target File: packages/finark-core-java/src/main/java/com/finark/core/security/SecurityGrid.java
// BRS Mapping: BR-14 Cross-Language Unified Caching Contract
// ============================================================================

package com.finark.core.security;

import io.lettuce.core.RedisClient;
import io.lettuce.core.api.StatefulRedisConnection;
import io.lettuce.core.api.sync.RedisCommands;
import com.auth0.jwt.JWT;
import com.auth0.jwt.algorithms.Algorithm;
import com.auth0.jwt.interfaces.DecodedJWT;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.util.List;
import java.util.Map;
import java.util.HashMap;

public class SecurityGrid {
    private final String jwtSecret;
    private final RedisCommands<String, String> syncCommands;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public SecurityGrid(String valkeyHost, int valkeyPort, String jwtSecret) {
        this.jwtSecret = jwtSecret;
        // Lettuce utilizes the standard redis:// scheme to negotiate socket communication handles
        RedisClient redisClient = RedisClient.create("redis://" + valkeyHost + ":" + valkeyPort);
        StatefulRedisConnection<String, String> connection = redisClient.connect();
        this.syncCommands = connection.sync();
    }

    // 🔌 Package-private constructor explicitly designed to allow clean Mock injection without reflection overhead
    SecurityGrid(String jwtSecret, RedisCommands<String, String> syncCommands) {
        this.jwtSecret = jwtSecret;
        this.syncCommands = syncCommands;
    }

    public boolean grant(String tokenUuid, long subjectId, List<String> roles, long ttlSeconds) {
        try {
            Map<String, Object> envelope = new HashMap<>();
            envelope.put("sub_id", subjectId);
            envelope.put("roles", roles);
            envelope.put("metadata", new HashMap<>());
            
            String serialized = objectMapper.writeValueAsString(envelope);
            // 🔐 Hardened: Aligned keyspace naming strings exactly with python/nestjs core targets
            String cacheKey = "auth_session:" + tokenUuid;
            
            syncCommands.setex(cacheKey, ttlSeconds, serialized);
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    public Map<String, Object> isValid(String rawToken) {
        try {
            Algorithm algorithm = Algorithm.HMAC256(jwtSecret);
            DecodedJWT jwt = JWT.require(algorithm).build().verify(rawToken);
            String tokenUuid = jwt.getClaim("jti").asString();
            if (tokenUuid == null) return null;
            
            // 🔐 Hardened: Aligned keyspace naming strings exactly with python/nestjs core targets
            String cacheKey = "auth_session:" + tokenUuid;
            String rawSession = syncCommands.get(cacheKey);
            if (rawSession == null) return null;
            
            // ✅ Java 25 Type Safety: Explicit TypeReference prevents unchecked conversion warnings
            return objectMapper.readValue(rawSession, new TypeReference<Map<String, Object>>() {});
        } catch (Exception e) {
            return null;
        }
    }

    public boolean revoke(String tokenUuid) {
        try {
            String cacheKey = "auth_session:" + tokenUuid;
            syncCommands.del(cacheKey);
            return true;
        } catch (Exception e) {
            return false;
        }
    }
}
