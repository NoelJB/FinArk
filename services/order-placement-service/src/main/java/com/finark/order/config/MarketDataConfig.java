// ============================================================================
// FINARK CORE PLATFORM CHASSIS SDK - HARDENED LETTUCE TIMEOUT BOUNDARY CONFIG
// Target File: services/order-placement-service/src/main/java/com/finark/order/config/MarketDataConfig.java
// BRS Mapping: BR-14 Non-Blocking Cache Thread Isolation
// ============================================================================

package com.finark.order.config;

import com.finark.core.market.MarketDataService;
import com.finark.core.market.MarketDataServiceImpl;
import io.lettuce.core.RedisClient;
import io.lettuce.core.RedisURI;
import io.lettuce.core.ClientOptions;
import io.lettuce.core.TimeoutOptions;
import io.lettuce.core.api.sync.RedisCommands;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.nio.file.Files;
import java.nio.file.Paths;
import java.time.Duration;

@Configuration
public class MarketDataConfig {

    @Bean
    public RedisCommands<String, String> syncCommands(
						      @Value("${VALKEY_HOST:localhost}") String host,
						      @Value("${VALKEY_PORT:6379}") int port) {
    
	// 🟢 FINALIZED CALIBRATION: Extended connection and command execution bounds to 5 seconds
	RedisURI redisUri = RedisURI.builder()
            .withHost(host)
            .withPort(port)
            .withTimeout(Duration.ofSeconds(5))
            .build();

	RedisClient client = RedisClient.create(redisUri);

	ClientOptions options = ClientOptions.builder()
            .timeoutOptions(TimeoutOptions.builder()
			    .fixedTimeout(Duration.ofSeconds(5))
			    .build())
            .build();
	client.setOptions(options);

	return client.connect().sync();
    }

    @Bean
    public MarketDataService marketDataService(
            RedisCommands<String, String> syncCommands,
            @Value("${fauxnance.api.url}") String urlValue,
            @Value("${fauxnance.api.key}") String keyValue) {
        
        String resolvedUrl = resolveSecretContent(urlValue);
        String resolvedKey = resolveSecretContent(keyValue);

        return new MarketDataServiceImpl(syncCommands, resolvedUrl, resolvedKey);
    }

    private String resolveSecretContent(String configValue) {
        if (configValue != null && configValue.startsWith("/run/secrets/")) {
            try {
                return new String(Files.readAllBytes(Paths.get(configValue))).trim();
            } catch (Exception e) {
                return configValue;
            }
        }
        return configValue;
    }
}
