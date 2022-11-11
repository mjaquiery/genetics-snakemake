# genetics-snakemake

## Running on the HPC cluster

### Clone the repository

```shell
git clone https://github.com/mjaquiery/genetics-snakemake
cd genetics-snakemake
```

###  Install `snakemake` via `conda` on the cluster
This requires `snakemake` to be installed from the `bioconda` channel. 

```shell
module load conda # or anaconda, or whatever the cluster offers

conda env create -p envs/smake --file=envs/environment.yaml # create conda environment from the project's YAML file

conda activate envs/smake # activate environment. Use conda deactivate to quit
# If you need to remove it to reset, use conda env remove -p envs/smake
```

### Run the slurmtest script

```shell
snakemake --profile envs/config.yaml test
```

You should now have `data` and `results` directories with various `hiworld.txt` files. Success!
