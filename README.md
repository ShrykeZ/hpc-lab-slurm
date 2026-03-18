# hpc-lab-slurm

Slurm GPU cluster lab for Ubuntu 22.04.

This repo contains a small three-node Slurm layout with accounting and telemetry:

- `slurm-ctrl`: controller and login node running `slurmctld`, `slurmdbd`, MariaDB, and Prometheus
- `slurm-gpu01`: GPU compute node running `slurmd` and DCGM exporter
- `slurm-gpu02`: GPU compute node or CPU-only node running `slurmd`
- shared authentication with Munge
- GPU scheduling through Slurm GRES
- accounting through `slurmdbd` backed by MariaDB
- GPU telemetry through DCGM exporter and Prometheus
- sample `srun` and `sbatch` jobs for checks

Use it either as:

1. a reference for manual setup of `munge`, `slurmctld`, `slurmd`, `slurmdbd`, `slurm.conf`, and `gres.conf`
2. an Ansible deployment for rebuilding the cluster from inventory

## Topology

| Node | Role | Required Services | Notes |
| --- | --- | --- | --- |
| `slurm-ctrl` | controller/login | `munge`, `slurmctld`, `slurmdbd`, MariaDB, Prometheus | cluster control plane, accounting, and metrics |
| `slurm-gpu01` | GPU compute | `munge`, `slurmd`, DCGM exporter | requires a working NVIDIA driver |
| `slurm-gpu02` | GPU compute or CPU-only | `munge`, `slurmd`, optional DCGM exporter | set `gpu_count=0` for CPU-only use |

Architecture sketch: [docs/architecture.mmd](docs/architecture.mmd)

## Repository Layout

| Path | Purpose |
| --- | --- |
| `ansible/inventory.ini` | host inventory |
| `ansible/group_vars/` | cluster-wide, controller, and compute defaults |
| `ansible/roles/` | common setup, Munge, NVIDIA checks, Slurm controller, Slurm compute, accounting, Prometheus, DCGM exporter, validation |
| `jobs/` | sample `sbatch` and `srun` workloads |
| `docs/architecture.mmd` | cluster diagram |

## Requirements

- Ubuntu 22.04 on all nodes
- hostnames and DNS, or matching `/etc/hosts` entries
- passwordless SSH from the Ansible control host to each node
- a sudo-capable non-root user, for example `ubuntu`
- matching Slurm package availability on all nodes
- a working NVIDIA driver and `nvidia-smi` on GPU nodes
- outbound package and image access for MariaDB, Prometheus, Docker, and DCGM exporter installation

If you want Ansible to manage the NVIDIA driver package, set `nvidia_manage_driver: true` in [ansible/group_vars/compute.yml](ansible/group_vars/compute.yml).

Before deployment, change `slurmdbd_storage_password` in [ansible/group_vars/controller.yml](ansible/group_vars/controller.yml).

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
- installs MariaDB and `slurmdbd` on the controller
- renders `slurm.conf`, `slurmdbd.conf`, `cgroup.conf`, and `gres.conf`
- configures Prometheus on the controller
- configures DCGM exporter on GPU nodes
- checks Munge on each node
- checks `nvidia-smi` on GPU nodes
- runs `sinfo`, `scontrol show nodes`, `sacctmgr show cluster`, and metrics endpoint checks

## Validation

After deployment, run:

```bash
sinfo
scontrol show nodes
sacctmgr show cluster
srun -N1 --partition=gpu --gpus=1 nvidia-smi
sbatch jobs/gpu-test.sbatch
sbatch jobs/multi-node.sbatch
sbatch jobs/torch-bench.sbatch
curl http://slurm-ctrl:9090/-/ready
curl http://slurm-gpu01:9400/metrics
```

You should see:

- compute nodes in `idle`
- GPU nodes with `Gres=gpu:<count>`
- `CUDA_VISIBLE_DEVICES` set inside GPU jobs
- `sacctmgr` showing the cluster in `slurmdbd`
- Prometheus responding on port `9090`
- DCGM exporter serving metrics on port `9400`

## Known Limits

- `slurmdbd_storage_password` is a placeholder and should be replaced before deployment
- the DCGM exporter role uses Docker and the NVIDIA container toolkit on GPU nodes
- package names assume Ubuntu 22.04 and may need small changes on Rocky or Alma

## Further Work

1. Add Alertmanager and basic alert rules.
2. Add Slurm-specific exporter coverage for scheduler metrics.
3. Add NCCL and multi-node communication benchmarks.
4. Add CI for Ansible linting and syntax checks.
