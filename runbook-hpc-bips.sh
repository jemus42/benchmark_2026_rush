# Initialize the environment such that slurm and conda are available
module load conda

# Run once to install conda env, redis, R + renv
./setup-hpc.sh

# Note: README points to renv::restore(), but setup-hpc.sh installs freshly into bare renv
# -> should be conditional maybe, if renv.lock exists, restore, otherwise fresh?

# Activate the conda environment, which includes redis
conda activate benchmark_2026_rush

# hq is a binary in the project directory, project dir needs to be in $PATH
# (adapt ./modules or in my case using .envrc with `direnv`)
# For modules, maybe use machine-agnistic PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd):$PATH" instead of hardcoding PATH?
./hq_server.sh        # nohup, stays in this shell's session keep in tmux or so
./hq_workers.sh       # one Slurm job, 6 nodes with my setup
hq worker list        # wait until 6 show up

./redis_server.sh &   # only needed for mbo/experiment.R
Rscript run_all.R
