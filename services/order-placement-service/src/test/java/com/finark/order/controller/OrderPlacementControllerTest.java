// ============================================================================
// FINARK PLATFORM - ORDER PLACEMENT REST BOUNDARY REGRESSION TESTS
// Target File: services/order-placement-service/src/test/java/com/finark/order/controller/OrderPlacementControllerTest.java
// BRS Mapping: BR-14 Automated Mock Testing Validation Matrix
// ============================================================================

package com.finark.order.controller;

import com.finark.order.dto.OrderSubmitRequest;
import com.finark.order.service.OrderPlacementService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import tools.jackson.databind.ObjectMapper;
import java.math.BigDecimal;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;

@WebMvcTest(OrderPlacementController.class)
public class OrderPlacementControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private OrderPlacementService orderPlacementService;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    public void submitOrder_MissingUserHeader_Returns401() throws Exception {
        // 🟢 Aligned: Explicitly pass 5 parameters: clientId, ticker, side, quantity, price
        OrderSubmitRequest requestPayload = new OrderSubmitRequest(1, "GLBEQ1", "BUY", BigDecimal.TEN, BigDecimal.ONE);
        
        mockMvc.perform(post("/api/v1/order-placement/submit")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(requestPayload)))
                .andExpect(status().isUnauthorized());
    }

    @Test
    public void submitOrder_NegativeQuantity_Returns400() throws Exception {
        // 🟢 Aligned: Explicitly pass 5 parameters: clientId, ticker, side, quantity, price
        OrderSubmitRequest requestPayload = new OrderSubmitRequest(1, "GLBEQ1", "BUY", new BigDecimal("-5.00"), BigDecimal.ONE);
        
        mockMvc.perform(post("/api/v1/order-placement/submit")
                .header("X-User-Id", "1")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(requestPayload)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Invalid Format: Quantity must be greater than zero"));
    }
}
