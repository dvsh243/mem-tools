#!/usr/bin/env python3
"""
Memory stress test - allocates RAM to force swap usage.
Supports gradual allocation over time.
"""

import sys
import time
import argparse

def format_bytes(b):
    for unit in ['B', 'KB', 'MB', 'GB']:
        if b < 1024:
            return f"{b:.1f} {unit}"
        b /= 1024
    return f"{b:.1f} TB"

def allocate_gradual(gb, duration_sec, chunk_mb=100):
    """Allocate memory gradually over specified duration, then hold."""
    total_bytes = int(gb * 1024**3)
    chunk_bytes = chunk_mb * 1024**2
    chunks = []
    
    # Calculate chunks and interval
    num_chunks = max(1, (total_bytes + chunk_bytes - 1) // chunk_bytes)
    interval = duration_sec / num_chunks
    
    print(f"Target: {format_bytes(total_bytes)} over {duration_sec}s")
    print(f"Chunks: {num_chunks} x {chunk_mb} MB (every {interval:.2f}s)")
    print("Press Ctrl+C to stop early and hold current allocation\n")
    
    try:
        allocated = 0
        chunk_num = 0
        
        while allocated < total_bytes:
            remaining = total_bytes - allocated
            this_chunk = min(chunk_bytes, remaining)
            
            # Allocate chunk
            chunks.append(bytearray(this_chunk))
            # Touch pages to ensure real allocation
            for i in range(0, this_chunk, 4096):
                chunks[-1][i] = 1
            
            allocated += this_chunk
            chunk_num += 1
            pct = (allocated / total_bytes) * 100
            print(f"  [{chunk_num}/{num_chunks}] {pct:.1f}% - Allocated: {format_bytes(allocated)} / {format_bytes(total_bytes)}")
            
            if allocated < total_bytes:
                time.sleep(interval)
        
        print(f"\n✓ Fully allocated {format_bytes(allocated)} over {duration_sec}s")
        print("Holding... Press Ctrl+C to release...")
        while True:
            time.sleep(10)
            
    except KeyboardInterrupt:
        print(f"\n\nReleasing {format_bytes(allocated)}...")
        chunks.clear()
        print("Done.")

def allocate_instant(gb, chunk_mb=500):
    """Allocate as fast as possible (original hold mode)."""
    total_bytes = int(gb * 1024**3)
    chunk_bytes = chunk_mb * 1024**2
    chunks = []
    
    print(f"Target: {format_bytes(total_bytes)} in {chunk_mb} MB chunks (instant)")
    print("Press Ctrl+C to free and exit\n")
    
    try:
        allocated = 0
        while allocated < total_bytes:
            remaining = total_bytes - allocated
            this_chunk = min(chunk_bytes, remaining)
            chunks.append(bytearray(this_chunk))
            for i in range(0, this_chunk, 4096):
                chunks[-1][i] = 1
            allocated += this_chunk
            print(f"  Allocated: {format_bytes(allocated)} / {format_bytes(total_bytes)}")
            time.sleep(0.05)
        
        print(f"\n✓ Holding {format_bytes(allocated)}. Press Ctrl+C to release...")
        while True:
            time.sleep(10)
            
    except KeyboardInterrupt:
        print("\n\nReleasing memory...")
        chunks.clear()
        print("Done.")

def allocate_continuous(gb, duration_sec, chunk_mb=200):
    """Continuously allocate/write/free for swap thrashing."""
    total_bytes = int(gb * 1024**3)
    chunk_bytes = chunk_mb * 1024**2
    iterations = 0
    start = time.time()
    
    print(f"Thrashing {format_bytes(total_bytes)} for {duration_sec}s ({chunk_mb} MB chunks)")
    print("Press Ctrl+C to stop early\n")
    
    try:
        while time.time() - start < duration_sec:
            data = bytearray(chunk_bytes)
            for i in range(0, chunk_bytes, 4096):
                data[i] = iterations & 0xFF
            del data
            iterations += 1
            
            if iterations % 10 == 0:
                elapsed = time.time() - start
                print(f"  Iteration {iterations}, elapsed: {elapsed:.1f}s")
                
    except KeyboardInterrupt:
        pass
    
    elapsed = time.time() - start
    print(f"\nDone: {iterations} iterations in {elapsed:.1f}s ({iterations/elapsed:.1f} iter/s)")

def main():
    parser = argparse.ArgumentParser(description="Memory stress test for swap testing")
    parser.add_argument("mode", choices=["gradual", "instant", "thrash"], 
                       help="gradual=allocate over time, instant=allocate fast, thrash=continuous alloc/free")
    parser.add_argument("gb", type=float, help="GB to allocate (can exceed RAM)")
    parser.add_argument("-t", "--time", type=int, default=10, 
                       help="Duration for gradual/thrash mode (seconds, default: 10)")
    parser.add_argument("-c", "--chunk", type=int, default=100,
                       help="Chunk size in MB (default: 100)")
    
    args = parser.parse_args()
    
    # Check available memory
    with open('/proc/meminfo') as f:
        for line in f:
            if line.startswith('MemAvailable:'):
                avail_kb = int(line.split()[1])
                print(f"System RAM available: {format_bytes(avail_kb * 1024)}")
                break
    
    if args.mode == "gradual":
        allocate_gradual(args.gb, args.time, args.chunk)
    elif args.mode == "instant":
        allocate_instant(args.gb, args.chunk)
    else:
        allocate_continuous(args.gb, args.time, args.chunk)

if __name__ == "__main__":
    main()