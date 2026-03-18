#!/bin/bash
#SBATCH --job-name=gpu-test
#SBATCH --partition=gpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-gpu=4
#SBATCH --gpus=1
#SBATCH --time=00:05:00

set -euo pipefail

hostname
echo "CUDA_VISIBLE_DEVICES=${CUDA_VISIBLE_DEVICES:-unset}"
nvidia-smi

python3 - <<'PY'
try:
    import torch
except ImportError:
    print("torch is not installed")
    raise

print("torch.cuda.is_available =", torch.cuda.is_available())
print("device_count =", torch.cuda.device_count())
if torch.cuda.is_available():
    print("device =", torch.cuda.get_device_name(0))
PY

