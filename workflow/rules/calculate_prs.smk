# Calculate Polygenic Risk Scores

rule calculate_valid_snps:
    resources:
        mem="150G"
    input:
        bed=os.path.join("{OUTPUT_DIR}", "{SOURCE}", "all.bed"),
        gwas=os.path.join("{OUTPUT_DIR}", "gwas", "gwas-03-disamb.tsv")
    output:
        os.path.join("{OUTPUT_DIR}", "{SOURCE}", "prs.all_score.valid")
    shell:
        """
        echo "Calculate PRS with PRSice:"
        in_filename={input.bed}
        in_filename=${{in_filename%.*}}
        Rscript ~/.tools/prsice/PRSice.R \
            --prsice ~/.tools/prsice/PRSice_linux \
            --base {input.gwas} \
            --out {output} \
            --target ${{in_filename}} \
            --snp rsID \
            --base-maf MAF:0.01 \
            --beta \
            --binary-target T \
            --clump-kb 250kb \
            --no-regress \
            --upper 1 \
            --bar-levels 1 \
            --thread 1 \
            --all-score \
            --fastscore || true  # ignore error we rerun below to handle
        """

rule calculate_prs:
    """
    Rerun because we need the first one to determine a list of valid SNPs.
    """
    resources:
        mem="150G"
    input:
        bed=os.path.join("{OUTPUT_DIR}", "{SOURCE}", "all.bed"),
        gwas=os.path.join("{OUTPUT_DIR}", "gwas", "gwas-03-disamb.tsv"),
        valid=os.path.join("{OUTPUT_DIR}", "{SOURCE}", "prs.all_score.valid")
    output:
        os.path.join("{OUTPUT_DIR}", "{SOURCE}", "prs.all_score")
    shell:
        """
        echo "Calculate PRS with PRSice:"
        in_filename={input.bed}
        in_filename=${{in_filename%.*}}
        Rscript ~/.tools/prsice/PRSice.R \
            --prsice ~/.tools/prsice/PRSice_linux \
            --base {input.gwas} \
            --out {output} \
            --target ${{in_filename}} \
            --snp rsID \
            --base-maf MAF:0.01 \
            --beta \
            --binary-target T \
            --clump-kb 250kb \
            --no-regress \
            --upper 1 \
            --bar-levels 1 \
            --thread 1 \
            --all-score \
            --fastscore \
            --extract {input.valid}           
        """
