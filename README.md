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
# On KCL CREATE we have to go via mamba 
conda create --name test-mamba -c conda-forge mamba
conda activate test-mamba
mamba create -c conda-forge -c bioconda -c r-tidyverse -n snakemake snakemake
# Run 'mamba init' to be able to run mamba activate/deactivate
# and start a new shell session. Or use conda to activate/deactivate.
# (test-mamba) $ mamba init
# (test-mamba) $ source ~/.bashrc
mamba activate snakemake
```


### Install qctool

At the moment we also need to install `qctool` because KCL's CREATE has an issue with the module.

```shell
cd ~/.tools
wget https://code.enkre.net/qctool/zip/release/qctool.tgz
# can take up some time: HTTP request sent, awaiting response... 302 Found
unzip qctool.tgz
cd qctool
./waf configure
./waf
~/.tools/qctool/build/release/apps/qctool_v2.2.0 -help

# At this point worth aliasing to qctool and adding to PATH
ln -s ~/.tools/qctool/build/release/apps/qctool_v2.2.0 ~/.tools/qctool/build/release/apps/qctool
echo "export PATH=~/.tools/qctool/build/release/apps/:$PATH" >> ~/.bashrc
```

Once we restart the shell to reexecute `.bashrc` and update the `PATH`,
we should have `qctool` available as a command:

```shell
qctool -help
```

### Install bcftools from samtools

http://www.htslib.org/download/

### Run the slurmtest script

```shell
snakemake --profile envs/config.yaml test
```

You should now have `data` and `results` directories with various `hiworld.txt` files. Success!


### Update the config

The config will need adjusting to your data sources. 
If they're the same as those in `config/CREATE_config.yaml` you can just replace the 
default config with that file:
```shell
rm -f config/config.yaml && mv config/*.yaml config/config.yaml
```

### Running directly (without submitting to scheduler)

This is how we currently have to run the commands.
Starting from the login, we request a node, then activate conda, then mamba, 
then our environment, then run Snakemake.

```shell
srun -p cpu --pty --mem=150G --ntasks=22 --time=24:00:00 /bin/bash
# CHANGE DIR (cd) to the repository directory if we're not already there!
# wait until the interactive node is available
conda activate test-mamba
mamba init
# activate our .bashrc file to mock shell restart
source ~/.bashrc
mamba activate snakemake
snakemake --cores 22 test
```

We're also having to do the data copy stage manually because I'm out of time to debug the automated version:
From in the repository directory:
```shell
cp -r ~/alspac/genetics/gi_1000g_g0m_g1/dosage_bgen results/gi_1000g_g0m_g1/bgen
cp -r ~/alspac/genetics/gi_1000g_g0p/dosage_bgen results/gi_1000g_g0p/bgen
```

They also need to be renamed from `filtered_data_chr#.bgen` to `chr_#.bgen`.

## Notes

- `plink1.9` and `plink2.0` are both required (sorry), and need to be available as commands in the runtime environment
- `PRSice` should be installed to `~/.tools/prsice/`
