package com.finark.order.config;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.context.annotation.Configuration;

@Configuration
@MapperScan("com.finark.order.mapper")
public class MyBatisConfig {
    // Keeps database schema scans isolated from web slice tests
}
