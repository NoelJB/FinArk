package com.finark.order.dto;

import java.math.BigDecimal;

public record OrderSubmitRequest(
    Integer clientId,
    String ticker,
    String side,
    BigDecimal quantity,
    BigDecimal price
) {}
