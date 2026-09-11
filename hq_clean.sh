# The login node's default Slurm cluster is `inter`, so pin scancel to cm4.
# export SLURM_CLUSTERS=cm4 # not needed on BIPS hpc

scancel --name=hq-workers
hq server stop
rm benchmark_2026_rush
rm nohup.out
