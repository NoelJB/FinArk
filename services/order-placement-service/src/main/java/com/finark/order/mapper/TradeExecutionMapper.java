package com.finark.order.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import java.math.BigDecimal;

@Mapper
public interface TradeExecutionMapper {

    @Select("SELECT id FROM instrument WHERE UPPER(ticker) = UPPER(CAST(#{ticker} AS VARCHAR))")
    Integer getInstrumentIdByTicker(@Param("ticker") String ticker);

    // 🟢 FIXED: Explicitly cast the bound string variable to match the exact schema type domain (canonical_currency)
    @Select("SELECT id FROM instrument WHERE instrument_type = 'CASH' AND currency = CAST(#{currency} AS canonical_currency)")
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

    @Select("SELECT CAST(currency AS VARCHAR) FROM instrument WHERE id = #{instrumentId}")
    String getCurrencyByInstrumentId(@Param("instrumentId") int instrumentId);
}
