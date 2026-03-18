#!/bin/bash
#SBATCH --job-name=torch-bench
#SBATCH --partition=gpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --gpus=1
#SBATCH --time=00:10:00

set -euo pipefail

python3 - <<'PY'
import time
import torch

device = "cuda"
n = 8192
a = torch.randn(n, n, device=device)
b = torch.randn(n, n, device=device)
torch.cuda.synchronize()
t0 = time.time()
for _ in range(20):
    _ = a @ b
torch.cuda.synchronize()
t1 = time.time()
elapsed = t1 - t0
print("elapsed", elapsed)
print("rough TFLOP/s", (2 * n * n * n * 20) / elapsed / 1e12)
PY
