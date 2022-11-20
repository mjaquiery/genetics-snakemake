"""
Snakemake file for processing genetic data and producing PRS and relatedness scores.

Snakemake is a workflow organiser. Snakemake is given a list of desired output files
(see rule all below), and if those files don't exist (or aren't up to date), for each
of those files it looks for a rule that can be used to generate it. The process is
then repeated for that rule -- if the files required to build _these files_ don't exist,
look for a rule that will produce them -- and so on.

Note: mum and child files are first trimmed down by father file availability to keep
data at manageable quantities
"""

import os.path

configfile: "config/config.yaml"

##### load rules #####
include: "rules/slurm-test.smk"

include: "rules/extract-subset.smk"
include: "rules/copy-data.smk"
include: "rules/clean_gwas.smk"
include: "rules/subset-bgen.smk"
include: "rules/qc_bed.smk"
include: "rules/examine-missingness.smk"
include: "rules/merge_bed.smk"
include: "rules/calculate_prs.smk"

# Constrain wildcards to NOT use /
wildcard_constraints:
    OUTPUT_DIR="[^/]+",
    SOURCE="[^/]+"

##### target rules #####

# Require the completed PRS and relatedness scores
rule all:
    input:
        os.path.join(config['output_dir'], "g0m", "prs.all_score"),
        os.path.join(config['output_dir'], "g0p", "prs.all_score")
        # os.path.join(f"{config['output_dir']}", "relatedness", "related.out")

# Remove intermediate directories
rule clean:
    shell:
        """
        rm -rf {config[output_dir]}/*/vcf &&
        rm -rf {config[output_dir]}/*/bed &&
        rm -rf {config[output_dir]}/*/bed_qc
        """

# Require the completed PRS and relatedness scores
rule test:
    input:
        expand(os.path.join(config['output_dir'], "slurmtest", "hiworld_{i}.txt"), i=range(1, 23))

"""
Test with
snakemake --cluster "sbatch" test
"""