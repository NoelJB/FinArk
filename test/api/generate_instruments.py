#!/usr/bin/env python3
# ============================================================================
# FINARK PLATFORM - REFERENCE INSTRUMENT REGISTRY COMPILER
# Target File: test/api/generate_instruments.py
# BRS Mapping: BR-14 Isolated Security Master Reference Ingestion
# ============================================================================

import os
import json

UNIVERSE_DIR = "./data/universes"
OUTPUT_SQL_PATH = "db/fixtures/01-canonical-instruments.sql"

def compile_canonical_instrument_catalog():
    print("⏳ Compiling canonical platform instrument data maps...")
    
    type_normalization_map = {
        "EQUITY": "STOCK", "ETF": "ETF", "FX": "CASH", "CRYPTO": "CRYPTO", "CASH": "CASH"
    }

    instrument_records = []
    
    # Establish persistent baseline system cash coordinates first
    instrument_records.append(("CASHGBP", "Cash - British Pound Sterling", "CASH", "GBP"))
    instrument_records.append(("CASHUSD", "Cash - United States Dollar", "CASH", "USD"))

    if os.path.exists(UNIVERSE_DIR):
        for filename in os.listdir(UNIVERSE_DIR):
            if filename.endswith(".json"):
                try:
                    with open(os.path.join(UNIVERSE_DIR, filename), "r", encoding="utf-8") as f:
                        file_data = json.load(f)
                        for s in file_data.get("symbols", []):
                            ticker = s.get("symbol")
                            name = s.get("name", "Unknown Corporate Asset").replace("'", "''")
                            raw_type = s.get("type", "EQUITY").upper()
                            currency = s.get("currency", "USD").upper()
                            
                            asset_type = type_normalization_map.get(raw_type, "STOCK")
                            if ticker in ("CASHGBP", "CASHUSD") or asset_type == "CASH":
                                continue
                                
                            instrument_records.append((ticker, name, asset_type, currency))
                except Exception as e:
                    print(f"⚠️ Error parsing file {filename}: {e}")
    else:
        # Secure fallback to baseline assets if the data loop path is cold
        instrument_records.extend([
            ("AAPL", "Apple Inc. Equity Asset", "STOCK", "USD"),
            ("MSFT", "Microsoft Corp. Equity Asset", "STOCK", "USD"),
            ("NVDA", "NVIDIA Corporation Equity Asset", "STOCK", "USD"),
            ("SPY", "SPDR S&P 500 ETF Trust", "ETF", "USD")
        ])

    # Build out-of-band pure reference SQL catalog file data
    sql_buffer = []
    sql_buffer.append("-- ============================================================================")
    sql_buffer.append("-- 01-canonical-instruments.sql: THE SECURE GLOBAL SECURITY REFERENCE MASTER")
    sql_buffer.append("-- Generated Out-of-Band via generate_instruments.py")
    sql_buffer.append("-- ============================================================================")
    sql_buffer.append("\\c paysprint;\n")
    
    sql_buffer.append("INSERT INTO instrument (ticker, name, instrument_type, currency, current_price) VALUES")
    
    for i, rec in enumerate(instrument_records):
        ticker, name, a_type, curr = rec
        comma = "," if i < len(instrument_records) - 1 else ";"
        # Initialize default pricing cleanly to 1.0000; updated hourly by the sidecar
        sql_buffer.append(f"('{ticker}', '{name}', '{a_type}', '{curr}', 1.0000){comma}")

    with open(OUTPUT_SQL_PATH, "w", encoding="utf-8") as out:
        out.write("\n".join(sql_buffer))
        
    print(f"✅ Master Instrument catalog compiled -> {OUTPUT_SQL_PATH} ({len(instrument_records)} assets linked)")

if __name__ == "__main__":
    compile_canonical_instrument_catalog()
