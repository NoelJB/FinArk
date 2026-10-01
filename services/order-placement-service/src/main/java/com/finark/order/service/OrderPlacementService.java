// ============================================================================
// FINARK PLATFORM - PRE-TRADE EXECUTION BUSINESS SERVICE LAYER
// Target File: services/order-placement-service/src/main/java/com/finark/order/service/OrderPlacementService.java
// BRS Mapping: BR-01 / BR-02 / Pre-Trade Validation Canopy
// ============================================================================

package com.finark.order.service;

import com.finark.order.dto.OrderSubmitRequest;
import com.finark.order.mapper.TradeExecutionMapper;
import com.finark.core.market.MarketDataService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;

@Service
public class OrderPlacementService {

    private final TradeExecutionMapper mapper;
    private final MarketDataService marketDataService;
    private static final BigDecimal MAX_PRICE_VARIANCE = new BigDecimal("0.05"); // 5% Variance Cap

    public OrderPlacementService(TradeExecutionMapper mapper, MarketDataService marketDataService) {
        this.mapper = mapper;
        this.marketDataService = marketDataService;
    }

    @Transactional
    public void processPreTradeOrderPlacement(int verifiedContextUserId, OrderSubmitRequest order) {
        
        // 🔒 MULTI-TENANT OWNERSHIP GUARD
        if (verifiedContextUserId != order.clientId()) {
            throw new IllegalArgumentException("Security Violation: Resource ownership mismatch. Operation aborted.");
        }

        // Resolve internal surrogate instrument ID
        Integer internalInstrumentId = mapper.getInstrumentIdByTicker(order.ticker());
        if (internalInstrumentId == null) {
            throw new IllegalArgumentException("Pre-Trade Violation: Targeted asset ticker '" + order.ticker() + "' not recognized.");
        }

        // Price Variance Guard targeting our Shared Read-Through SDK Layer
        BigDecimal currentMarketPrice = marketDataService.getCurrentPrice(internalInstrumentId, order.ticker());
        if (currentMarketPrice == null) {
            throw new IllegalArgumentException("Pre-Trade Violation: Targeted security price could not be resolved from cloud endpoint.");
        }

        BigDecimal priceDifference = order.price().subtract(currentMarketPrice).abs();
        BigDecimal variancePct = priceDifference.divide(currentMarketPrice, 4, RoundingMode.HALF_UP);
        if (variancePct.compareTo(MAX_PRICE_VARIANCE) > 0) {
            throw new IllegalArgumentException("Pre-Trade Violation: Order price deviance exceeds the 5% variance threshold.");
        }

        // 🛡️ Cash coverage and short-sale controls block transactions natively
	// services/order-placement-service/src/main/java/com/finark/order/service/OrderPlacementService.java
	if ("BUY".equalsIgnoreCase(order.side())) {
    
	    // 🟢 DYNAMIC RESOLUTION: Fetch the true settlement currency of the asset from the DB master
	    String targetCurrency = mapper.getCurrencyByInstrumentId(internalInstrumentId);
	    if (targetCurrency == null) {
		throw new IllegalStateException("System Error: Traded asset currency boundary is unmapped.");
	    }

	    Integer cashInstrumentId = mapper.getCashInstrumentIdByCurrency(targetCurrency);
	    if (cashInstrumentId == null) {
		throw new IllegalStateException("System Error: Capital settlement ledger for currency '" + targetCurrency + "' is uninitialized.");
	    }

	    BigDecimal totalOrderCost = order.quantity().multiply(order.price());
	    BigDecimal availableCash = mapper.getClientAssetBalance(order.clientId(), cashInstrumentId);
	    if (availableCash.compareTo(totalOrderCost) < 0) {
		throw new IllegalArgumentException("Pre-Trade Violation: Insufficient financial capital available.");
	    }
	} else if ("SELL".equalsIgnoreCase(order.side())) {
            BigDecimal availableShares = mapper.getClientAssetBalance(order.clientId(), internalInstrumentId);
            if (availableShares.compareTo(order.quantity()) < 0) {
                throw new IllegalArgumentException("Pre-Trade Violation: Insufficient share inventory. Uncollateralized short sales blocked.");
            }
        }

        // Route direct append-only insertion straight to the ledger
        mapper.insertExecution(order.clientId(), internalInstrumentId, order.side().toUpperCase(), order.quantity(), order.price());
    }
}
