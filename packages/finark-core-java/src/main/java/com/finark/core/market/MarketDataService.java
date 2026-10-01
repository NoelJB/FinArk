package com.finark.core.market;

import java.math.BigDecimal;

public interface MarketDataService {
    /**
     * Resolves the current market price for a given instrument using an 
     * in-memory read-through cache mechanism targeting the external Fauxnance API.
     */
    BigDecimal getCurrentPrice(int instrumentId, String ticker);
}
