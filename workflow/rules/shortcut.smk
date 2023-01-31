# Calculate Polygenic Risk Scores

rule bgen_to_vcf:
    input:
        bgen=os.path.join("{OUTPUT_DIR}","{SOURCE}","bgen","chr_{CHR}.bgen"),
        sample=lambda wildcards: config['data_dirs'][wildcards.SOURCE]['sample_file']
    output:
        temp(os.path.join("{OUTPUT_DIR}","{SOURCE}","vcf","chr_{CHR}.vcf"))
    shell:
        """
        out_filename={output}
        out_filename=${{out_filename%.*}}
        plink2 --bgen {input.bgen} ref-last snpid-chr --sample {input.sample} --export vcf --out "${{out_filename}}"
        """

rule filter_vcf:
    input:
        os.path.join("{OUTPUT_DIR}","{SOURCE}","vcf","chr_{CHR}.vcf")
    output:
        temp(os.path.join("{OUTPUT_DIR}","{SOURCE}","vcf","filtered_chr_{CHR}.vcf"))
    shell:
        """
        echo "WARNING: This step is skipped for the moment; PRS scores will be calculated for ALL participants!"
        mv {input} {output}
        """

rule vcf_to_bed:
    input:
        os.path.join("{OUTPUT_DIR}","{SOURCE}","vcf","filtered_chr_{CHR}.vcf")
    output:
        os.path.join("{OUTPUT_DIR}","{SOURCE}","bed","chr_{CHR}.bed")
    shell:
        """
        out_filename={output}
        out_filename=${{out_filename%.*}}
        plink2 --vcf {input} --make-bed --out "${{out_filename}}"
        """

rule prs:
    resources:
        mem="150G"
    input:
        bed=lambda wildcards: expand(
            os.path.join("{OUTPUT_DIR}","{SOURCE}","bed","chr_{i}.bed"),
            i=range(1, 23),
            OUTPUT_DIR=wildcards.OUTPUT_DIR,
            SOURCE=wildcards.SOURCE
        ),
        gwas=os.path.join("{OUTPUT_DIR}", "gwas", "gwas-03-disamb.tsv")
    output:
        os.path.join("{OUTPUT_DIR}", "{SOURCE}", "prs.valid")
    shell:
        """
        bed_prefix="{wildcards.OUTPUT_DIR}/{wildcards.SOURCE}/bed/chr_#"
        out_filename={output}
        out_filename=${{out_filename%.*}}
        Rscript ~/.tools/prsice/PRSice.R --prsice ~/.tools/prsice/PRSice_linux --base {input.gwas} --out ${{out_filename}} --snp rsID --no-regress --all-score --fastscore --beta --target ${{bed_prefix}} || true
        """


rule prs_valid:
    resources:
        mem="150G"
    input:
        bed=lambda wildcards: expand(
            os.path.join("{OUTPUT_DIR}","{SOURCE}","bed","chr_{i}.bed"),
            i=range(1, 23),
            OUTPUT_DIR=wildcards.OUTPUT_DIR,
            SOURCE=wildcards.SOURCE
        ),
        gwas=os.path.join("{OUTPUT_DIR}", "gwas", "gwas-03-disamb.tsv"),
        valid=os.path.join("{OUTPUT_DIR}", "{SOURCE}", "prs.valid")
    output:
        os.path.join("{OUTPUT_DIR}", "{SOURCE}", "prs.all_score")
    shell:
        """
        bed_prefix="{wildcards.OUTPUT_DIR}/{wildcards.SOURCE}/bed/chr_#"
        out_filename={output}
        out_filename=${{out_filename%.*}}
        Rscript ~/.tools/prsice/PRSice.R --prsice ~/.tools/prsice/PRSice_linux --base {input.gwas} --out ${{out_filename}} --snp rsID --no-regress --all-score --fastscore --beta --target ${{bed_prefix}} --extract results/tmp.valid
        """
