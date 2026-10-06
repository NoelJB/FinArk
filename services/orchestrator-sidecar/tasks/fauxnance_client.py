# services/orchestrator-sidecar/tasks/fauxnance_client.py
import sys
import time
import random
import requests

def fetch_market_quotes_with_deltas(url, api_key, symbols_iterable):
    """Iterates through all provided symbols in strict chunks of 25.
    
    Returns a tuple containing:
    1. A list of successfully parsed quote records: [(price, ticker), ...]
    2. A set of symbols that failed to fetch due to timeouts or server drops.
    """
    symbols_list = list(symbols_iterable)
    accumulated_results = []
    failed_symbols = set()
    
    # Strictly bound to the 25-item chunk limit enforced by the API Gateway
    chunks = [symbols_list[i:i + 25] for i in range(0, len(symbols_list), 25)]
    base_backoff = 2.0
    
    for i, chunk in enumerate(chunks):
        symbols_query_string = ",".join(chunk)
        chunk_success = False
        
        # In-line Exponential Backoff loop for transient network drops
        for attempt in range(3):
            print(f"Attemping to get Chunk #{i}, Attempt: {attempt}, Size: {len(chunk)}", flush=True)
            try:
                res = requests.get(
                    url,
                    headers={"X-API-Key": api_key},
                    params={"symbols": symbols_query_string},
                    timeout=10
                )
                
                if res.status_code == 200:
                    data = res.json()
                    quotes_array = data.get("data", {}).get("quotes", [])
                    print(f" - Received {len(quotes_array)} quotes.", flush=True)
                    for item in quotes_array:
                        inner_q = item.get("quote", {})
                        t = inner_q.get("symbol")
                        p = inner_q.get("price")
                        if t and p is not None:
                            accumulated_results.append((p, t))
                    chunk_success = True
                    break
                    
                elif res.status_code in (202, 429):
                    retry_after = int(res.headers.get("Retry-After", 4))
                    print(f"⏳ [Fauxnance {res.status_code}] Waiting {retry_after}s...", file=sys.stderr, flush=True)
                    time.sleep(retry_after)
                    continue
                    
                elif res.status_code in (500, 502, 503, 504):
                    sleep_duration = (base_backoff ** attempt) + random.uniform(0.1, 0.5)
                    print(f"⚠️ [Fauxnance {res.status_code}] Transient drop. Retry in {sleep_duration:.2f}s...", file=sys.stderr, flush=True)
                    time.sleep(sleep_duration)
                    continue
                else:
                    print(f"FAUXNANCE Hard Contract Error: {res.status_code} from {url}", file=sys.stderr, flush=True)
                    break
                    
            except (requests.exceptions.Timeout, requests.exceptions.ConnectionError) as net_err:
                sleep_duration = (base_backoff ** attempt) + random.uniform(0.1, 0.5)
                print(f"⚠️ [market-sync] Socket timeout: {net_err}. Retry in {sleep_duration:.2f}s...", file=sys.stderr, flush=True)
                time.sleep(sleep_duration)
                continue
        
        if not chunk_success:
            # If all retries for this specific chunk failed, mark its elements for future delta retries
            print(f"❌ [fauxnance-client] Chunk of {len(chunk)} symbols completely dropped. Added to delta pool.", file=sys.stderr, flush=True)
            failed_symbols.update(chunk)
            
        # Pacing delay to gracefully shield cloud gateway capacity limits
        time.sleep(0.1)

    print(f"Faunnance Batch Complete: {len(accumulated_results)} loaded, {len(failed_symbols)} to retry.") 
    return accumulated_results, failed_symbols
