# hpc-lab-slurm

Slurm GPU cluster lab for Ubuntu 22.04.

This repo contains a small three-node Slurm layout:

- `slurm-ctrl`: controller and login node running `slurmctld`
- `slurm-gpu01`: GPU compute node running `slurmd`
- `slurm-gpu02`: GPU compute node or CPU-only node running `slurmd`
- shared authentication with Munge
- GPU scheduling through Slurm GRES
- sample `srun` and `sbatch` jobs for checks

Use it either as:

1. a reference for manual setup of `munge`, `slurmctld`, `slurmd`, `slurm.conf`, and `gres.conf`
2. an Ansible deployment for rebuilding the cluster from inventory

## Topology

| Node | Role | Required Services | Notes |
| --- | --- | --- | --- |
| `slurm-ctrl` | controller/login | `munge`, `slurmctld` | cluster control plane |
| `slurm-gpu01` | GPU compute | `munge`, `slurmd` | requires a working NVIDIA driver |
| `slurm-gpu02` | GPU compute or CPU-only | `munge`, `slurmd` | set `gpu_count=0` for CPU-only use |

Architecture sketch: [docs/architecture.mmd](docs/architecture.mmd)

## Repository Layout

| Path | Purpose |
| --- | --- |
| `ansible/inventory.ini` | host inventory |
| `ansible/group_vars/` | cluster-wide, controller, and compute defaults |
| `ansible/roles/` | common setup, Munge, NVIDIA checks, Slurm controller, Slurm compute, validation |
| `jobs/` | sample `sbatch` and `srun` workloads |
| `docs/architecture.mmd` | simple cluster diagram |

## Requirements

- Ubuntu 22.04 on all nodes
- hostnames and DNS, or matching `/etc/hosts` entries
- passwordless SSH from the Ansible control host to each node
- a sudo-capable non-root user, for example `ubuntu`
- matching Slurm package availability on all nodes
- a working NVIDIA driver and `nvidia-smi` on GPU nodes

If you want Ansible to manage the NVIDIA driver package, set `nvidia_manage_driver: true` in [ansible/group_vars/compute.yml](ansible/group_vars/compute.yml).

## Deployment

Update [ansible/inventory.ini](ansible/inventory.ini) with your node IPs and SSH user, then run:

```bash
ansible-playbook -i ansible/inventory.ini ansible/site.yml
```

The playbook:

- installs base packages such as `munge`, `slurm-client`, and `chrony`
- creates and distributes a shared Munge key
- installs and configures `slurmctld` on the controller
- installs and configures `slurmd` on compute nodes
- renders `slurm.conf`, `cgroup.conf`, and `gres.conf`
- checks Munge on each node
- checks `nvidia-smi` on GPU nodes
- runs `sinfo` and `scontrol show nodes` from the controller

## Validation

After deployment, run:

```bash
sinfo
scontrol show nodes
srun -N1 --partition=gpu --gpus=1 nvidia-smi
sbatch jobs/gpu-test.sbatch
sbatch jobs/multi-node.sbatch
sbatch jobs/torch-bench.sbatch
```

You should see:

- compute nodes in `idle`
- GPU nodes with `Gres=gpu:<count>`
- `CUDA_VISIBLE_DEVICES` set inside GPU jobs
- one-node and two-node jobs finishing without daemon or authentication errors

## Known Limits

- `slurmdbd` and accounting are not included
- DCGM exporter, Prometheus, and NCCL tests are left for later
- package names assume Ubuntu 22.04 and may need small changes on Rocky or Alma

## Further Work

1. Add `slurmdbd` with MySQL or MariaDB-backed accounting. [In Dev]
2. Add DCGM exporter and Prometheus for GPU telemetry. [In Dev]
3. Add NCCL and multi-node communication benchmarks.
4. Add CI for Ansible linting and syntax checks.
