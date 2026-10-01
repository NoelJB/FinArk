package com.finark.order.config;

import com.finark.core.market.MarketDataService;
import com.finark.core.market.MarketDataServiceImpl;
import io.lettuce.core.RedisClient;
import io.lettuce.core.api.sync.RedisCommands;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.nio.file.Files;
import java.nio.file.Paths;

@Configuration
public class MarketDataConfig {

    @Bean
    public RedisCommands<String, String> syncCommands(
            @Value("${VALKEY_HOST:localhost}") String host,
            @Value("${VALKEY_PORT:6379}") int port) {
        RedisClient client = RedisClient.create("redis://" + host + ":" + port);
        return client.connect().sync();
    }

    @Bean
    public MarketDataService marketDataService(
            RedisCommands<String, String> syncCommands,
            @Value("${fauxnance.api.url}") String urlValue,
            @Value("${fauxnance.api.key}") String keyValue) {
        
        // 🔐 Hardened: If properties indicate a file-based container secret path, read and unpack contents safely
        String resolvedUrl = resolveSecretContent(urlValue);
        String resolvedKey = resolveSecretContent(keyValue);

        return new MarketDataServiceImpl(syncCommands, resolvedUrl, resolvedKey);
    }

    private String resolveSecretContent(String configValue) {
        if (configValue != null && configValue.startsWith("/run/secrets/")) {
            try {
                return new String(Files.readAllBytes(Paths.get(configValue))).trim();
            } catch (Exception e) {
                // Return original property value on error to support fallback local mechanics cleanly
                return configValue;
            }
        }
        return configValue;
    }
}
