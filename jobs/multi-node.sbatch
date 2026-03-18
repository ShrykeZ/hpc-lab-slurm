#!/bin/bash
#SBATCH --job-name=multi-node
#SBATCH --partition=gpu
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=1
#SBATCH --gpus-per-node=1
#SBATCH --time=00:05:00

set -euo pipefail

srun bash -lc 'hostname; echo CUDA_VISIBLE_DEVICES=${CUDA_VISIBLE_DEVICES:-unset}; nvidia-smi --query-gpu=name,uuid --format=csv,noheader'

