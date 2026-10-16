package com.finark.order.config;

import javax.sql.DataSource;
import java.nio.file.Files;
import java.nio.file.Paths;
import org.apache.ibatis.session.SqlSessionFactory;
import org.mybatis.spring.SqlSessionFactoryBean;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.jdbc.DataSourceBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.context.annotation.Profile; // 🟢 REQUIRED
import org.springframework.core.io.support.PathMatchingResourcePatternResolver;

@Configuration
@Profile("!test") // 🟢 SECURE INVARIANT: Isolated away from active test profiles to skip unmounted secrets processing offline
public class DataSourceConfig {

    @Value("${spring.datasource.url}")
    private String dbUrl;

    @Value("${spring.datasource.username}")
    private String dbUsername;

    @Value("${spring.datasource.driver-class-name}")
    private String driverClassName;

    @Value("${spring.datasource.password}")
    private String passwordConfigValue;

    @Bean
    @Primary
    public DataSource dataSource() {
        System.out.println("☕ [order-placement/DataSourceConfig] Initializing connection pool layout over URL: " + dbUrl);
        System.out.println("☕ [order-placement/DataSourceConfig] Raw password property string input context: " + passwordConfigValue);

        String resolvedPassword = passwordConfigValue;

        if (passwordConfigValue != null && passwordConfigValue.startsWith("/run/secrets/")) {
            try {
                System.out.println("🔒 [order-placement/DataSourceConfig] Docker Secret route matched. Attempting to parse in-memory file bytes...");
                resolvedPassword = new String(Files.readAllBytes(Paths.get(passwordConfigValue))).trim();
                System.out.println("✅ [order-placement/DataSourceConfig] File credentials successfully loaded into application memory pool.");
            } catch (Exception e) {
                System.out.println("⚠️ [order-placement/DataSourceConfig] Secret extraction failure: " + e.getMessage() + ". Defaulting to property string fallback.");
                resolvedPassword = passwordConfigValue;
            }
        } else {
            System.out.println("ℹ️ [order-placement/DataSourceConfig] Non-secret property configuration matched. Skipping file extraction steps.");
        }

        return DataSourceBuilder.create()
                .url(dbUrl)
                .username(dbUsername)
                .password(resolvedPassword)
                .driverClassName(driverClassName)
                .build();
    }

    @Bean
    public SqlSessionFactory sqlSessionFactory(DataSource dataSource) throws Exception {
        System.out.println("☕ [order-placement/DataSourceConfig] Instantiating custom MyBatis SqlSessionFactory lifecycle factory...");
        
        SqlSessionFactoryBean factoryBean = new SqlSessionFactoryBean();
        factoryBean.setDataSource(dataSource);
        
        PathMatchingResourcePatternResolver resolver = new PathMatchingResourcePatternResolver();
        factoryBean.setMapperLocations(resolver.getResources("classpath:mapper/*.xml"));
        
        org.apache.ibatis.session.Configuration configuration = new org.apache.ibatis.session.Configuration();
        configuration.setMapUnderscoreToCamelCase(true);
        factoryBean.setConfiguration(configuration);
        
        SqlSessionFactory builtSessionFactory = factoryBean.getObject();
        System.out.println("✅ [order-placement/DataSourceConfig] SqlSessionFactory built successfully. Mapper bindings available.");
        return builtSessionFactory;
    }
}
