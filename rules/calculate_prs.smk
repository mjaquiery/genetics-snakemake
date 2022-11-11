# Calculate Polygenic Risk Scores

rule calculate_prs:
    resources:
        mem="150G"
    input:
        bed=os.path.join("{OUTPUT_DIR}", "{ROLE}", "all.bed"),
        gwas=os.path.join("{OUTPUT_DIR}", "gwas", "gwas-03-disamb.tsv")
    output:
        os.path.join("{OUTPUT_DIR}", "{ROLE}", "prs.all_score")
    shell:
        """
        PRSice_linux \
            --base {input} \
            --snp SNP \
            --a1 A1 \
            --a2 A2 \
            --bp POS \
            --chr CHR \
            --beta \
            --pvalue P \
            --stat BETA \
            --target {input.bed} \
            --clump-kb 250kb \
            --base-maf EAF:0.01 \
            --no-regress \
            --upper 1 \
            --bar-levels 1 \
            --thread 1 \
            --out {output} \
            --all-score \
            --fastscore
        """
