#!/bin/bash

# Starts the HyperQueue workers for one benchmark run as a *single* multi-node Slurm job
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# The login node's default Slurm cluster is `inter`, so pin sbatch to cm4.
export SLURM_CLUSTERS=cm4

N_NODES=4
CPUS_PER_NODE=112

mkdir -p "${PROJECT_DIR}/logs"

# srun needs a real executable, so the environment setup goes through `bash -c`
# instead of being handed to srun as a bare `source`. Workers stop a little
# before the walltime so they can deregister instead of being killed.
WORKER_CMD="source ${PROJECT_DIR}/hq_env.sh && exec ${PROJECT_DIR}/hq worker start --manager slurm --cpus ${CPUS_PER_NODE} --idle-timeout 2h --on-server-lost finish-running --time-limit 23h55m"

sbatch --clusters=cm4 \
  --partition=cm4_std \
  --qos=cm4_std \
  --job-name=hq-workers \
  --nodes=${N_NODES} \
  --ntasks-per-node=${CPUS_PER_NODE} \
  --time=24:00:00 \
  --output="${PROJECT_DIR}/logs/hq_workers_%j.log" \
  --get-user-env \
  --export=NONE <<EOF
#!/bin/bash
# --export=NONE leaves SLURM_EXPORT_ENV=NONE in this script's environment. srun
# inherits that and applies it to its steps, so the tasks would start with an
# empty environment and die on "execve(): bash: No such file or directory".
# This script's own environment is the login environment built by
# --get-user-env, which is exactly what the workers need, so pass it on.
export SLURM_EXPORT_ENV=ALL

# One task per node, each becoming one HyperQueue worker with ${CPUS_PER_NODE} cpus.
# /bin/bash by absolute path, so the step does not depend on PATH being set up.
srun --nodes=${N_NODES} --ntasks=${N_NODES} --ntasks-per-node=1 --overlap /bin/bash -c '${WORKER_CMD}'
EOF
