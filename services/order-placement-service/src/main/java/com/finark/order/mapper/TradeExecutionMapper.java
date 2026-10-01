package com.finark.order.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import java.math.BigDecimal;
import java.util.List;

@Mapper
public interface TradeExecutionMapper {
    
    // 🔍 Hardened: Resolves the local surrogate primary key ID from the ticker string token
    @Select("SELECT id FROM instrument WHERE UPPER(ticker) = UPPER(#{ticker})")
    Integer getInstrumentIdByTicker(@Param("ticker") String ticker);

    @Select("SELECT COALESCE(SUM(quantity), 0) FROM client_instrument WHERE client_id = #{clientId} AND instrument_id = #{instrumentId}")
    BigDecimal getClientAssetBalance(@Param("clientId") int clientId, @Param("instrumentId") int instrumentId);

    void insertExecution(
        @Param("clientId") int clientId,
        @Param("instrumentId") int instrumentId,
        @Param("side") String side,
        @Param("quantity") BigDecimal quantity,
        @Param("price") BigDecimal price
    );
}
