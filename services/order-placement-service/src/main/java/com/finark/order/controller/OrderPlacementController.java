// ============================================================================
// FINARK PLATFORM - ORDER PLACEMENT CONTROLLER ENTRY BOUNDARY
// Target File: services/order-placement-service/src/main/java/com/finark/order/controller/OrderPlacementController.java
// BRS Mapping: BR-01 Perimeter Security Type Canopy
// ============================================================================

package com.finark.order.controller;

import com.finark.order.dto.OrderSubmitRequest;
import com.finark.order.service.OrderPlacementService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.Map;

@RestController
@RequestMapping("/api/v1") // the local context for this controller, which is at least the root of this service
public class OrderPlacementController {

    private final OrderPlacementService orderPlacementService;

    public OrderPlacementController(OrderPlacementService orderPlacementService) {
        this.orderPlacementService = orderPlacementService;
    }

    @PostMapping("/submit")
    public ResponseEntity<?> submitOrder(
            @RequestHeader(value = "X-User-Id", required = false) String headerUserId,
            @RequestBody OrderSubmitRequest request) {

        // 🔍 TELEMETRY DIAGNOSTIC
        System.out.println("☕ [order-placement] Inbound endpoint transaction intercepted under path: POST /api/v1/submit");
        System.out.println("☕ [order-placement] Telemetry context tracking header - X-User-Id: " + headerUserId);
        System.out.println("☕ [order-placement] Inbound payload values: " + request);

        if (headerUserId == null || headerUserId.trim().isEmpty()) {
            System.out.println("❌ [order-placement] Execution Blocked: Perimeter verification context missing from request headers");
            return ResponseEntity.status(401).body(Map.of("error", "Perimeter authentication security context missing"));
        }
        
        int verifiedContextUserId;
        try {
            verifiedContextUserId = Integer.parseInt(headerUserId);
        } catch (NumberFormatException e) {
            System.out.println("❌ [order-placement] Execution Blocked: Malformed X-User-Id context signature parsed");
            return ResponseEntity.badRequest().body(Map.of("error", "Malformed tracking context parameter signature"));
        }

        // Strict REST Format Validation Gates
        if (request.clientId() == null) {
            return ResponseEntity.badRequest().body(Map.of("error", "Invalid Format: Missing client_id"));
        }
        if (request.ticker() == null || request.ticker().trim().isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("error", "Invalid Format: Missing asset ticker"));
        }
        if (request.side() == null || (!request.side().equalsIgnoreCase("BUY") && !request.side().equalsIgnoreCase("SELL"))) {
            return ResponseEntity.badRequest().body(Map.of("error", "Invalid Format: Side must evaluate to 'BUY' or 'SELL'"));
        }
        if (request.quantity() == null || request.quantity().compareTo(BigDecimal.ZERO) <= 0) {
            return ResponseEntity.badRequest().body(Map.of("error", "Invalid Format: Quantity must be greater than zero"));
        }
        if (request.price() == null || request.price().compareTo(BigDecimal.ZERO) <= 0) {
            return ResponseEntity.badRequest().body(Map.of("error", "Invalid Format: Price must be greater than zero"));
        }

        // Delegate execution down to our decoupled business logic service tier
        try {
            orderPlacementService.processPreTradeOrderPlacement(verifiedContextUserId, request);
            System.out.println("✅ [order-placement] Pre-Trade Invariants passed. Append-only ledger row generated successfully.");
            return ResponseEntity.ok(Map.of(
                "status", "ORDER_PLACED_SUCCESSFULLY",
                "client_id", verifiedContextUserId,
                "domain_strategy", "DECOUPLED_PRE_TRADE_SERVICE_MATRIX"
            ));
        } catch (IllegalArgumentException e) {
            System.out.println("❌ [order-placement] Pre-Trade business invariant check failed: " + e.getMessage());
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        } catch (Exception e) {
            System.out.println("💥 [order-placement] Critical data infrastructure write failure: " + e.getMessage());
            return ResponseEntity.status(500).body(Map.of("error", "Internal business transaction error", "details", e.getMessage()));
        }
    }
}
