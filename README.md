# mem-tools

A collection of memory management and stress testing tools for Linux systems.

## Overview

This repository contains scripts and utilities for managing swap space and testing memory behavior on Linux systems.

## Files

| File | Description |
|------|-------------|
| `create_swap.sh` | Creates a swap file of specified size |
| `activate_swap.sh` | Activates an existing swap file |
| `kill_swap.sh` | Deactivates and removes a swap file |
| `mem_stress.sh` | Shell script for memory stress testing |
| `mem_stress.py` | Python script for advanced memory stress testing |

## Usage

### Swap Management

```bash
# Create a 4GB swap file
sudo ./create_swap.sh 4G

# Activate the swap file
sudo ./activate_swap.sh

# Deactivate and remove swap file
sudo ./kill_swap.sh
```

### Memory Stress Testing

```bash
# Run shell-based memory stress test
./mem_stress.sh

# Run Python-based memory stress test (more options)
python3 mem_stress.py --help
```

## Requirements

- Linux system with root/sudo access for swap management
- Python 3.x for `mem_stress.py`
- Bash for shell scripts

## License

MIT License - Feel free to use and modify as needed.