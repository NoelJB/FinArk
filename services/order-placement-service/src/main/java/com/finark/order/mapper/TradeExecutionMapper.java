package com.finark.order.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import java.math.BigDecimal;

@Mapper
public interface TradeExecutionMapper {
    
    @Select("SELECT id FROM instrument WHERE UPPER(ticker) = UPPER(#{ticker})")
    Integer getInstrumentIdByTicker(@Param("ticker") String ticker);

    // 🟢 REFACTORED: Resolves the unique primary key ID based on asset metadata instead of hardcoded numbers
    @Select("SELECT id FROM instrument WHERE instrument_type = 'CASH' AND currency = #{currency}")
    Integer getCashInstrumentIdByCurrency(@Param("currency") String currency);

    @Select("SELECT COALESCE(SUM(quantity), 0) FROM client_instrument WHERE client_id = #{clientId} AND instrument_id = #{instrumentId}")
    BigDecimal getClientAssetBalance(@Param("clientId") int clientId, @Param("instrumentId") int instrumentId);

    void insertExecution(
        @Param("clientId") int clientId,
        @Param("instrumentId") int instrumentId,
        @Param("side") String side,
        @Param("quantity") BigDecimal quantity,
        @Param("price") BigDecimal price
    );

    @Select("SELECT currency FROM instrument WHERE id = #{instrumentId}")
    String getCurrencyByInstrumentId(@Param("instrumentId") int instrumentId);
}
