// ============================================================================
// FINARK CORE PLATFORM CHASSIS SDK - JAVA REGRESSION TEST MATRIX
// Target File: packages/finark-core-java/src/test/java/com/finark/core/security/SecurityGridTest.java
// BRS Mapping: BR-14 Automated Mock Testing Validation
// ============================================================================

package com.finark.core.security;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import io.lettuce.core.api.sync.RedisCommands;
import java.util.List;

import static org.mockito.Mockito.*;
import static org.junit.jupiter.api.Assertions.*;

@ExtendWith(MockitoExtension.class)
public class SecurityGridTest {
    private SecurityGrid securityGrid;
    
    @Mock 
    private RedisCommands<String, String> syncCommands;
    
    private final String secret = "test-shared-cryptographic-secret-key-32-bytes";

    @BeforeEach
    public void setup() {
        // ✅ Hardened: Swapped reflection manipulation for explicit type-safe constructor injection
        securityGrid = new SecurityGrid(secret, syncCommands);
    }

    @Test
    public void testGrant() {
        when(syncCommands.setex(anyString(), anyLong(), anyString())).thenReturn("OK");
        
        boolean res = securityGrid.grant("uuid-1", 3L, List.of("GUEST"), 3600L);
        
        assertTrue(res);
        // 🔐 Hardened: Aligned verification assertions exactly with our auth_session: contract
        verify(syncCommands).setex(eq("auth_session:uuid-1"), eq(3600L), anyString());
    }
}
