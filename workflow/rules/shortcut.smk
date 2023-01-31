# Calculate Polygenic Risk Scores

rule download_code_map:
    output:
        os.path.join("{OUTPUT_DIR}","recode_map","common_all_20170710.vcf.gz")
    shell:
        """
        wget ftp://ftp.ncbi.nih.gov/snp/organisms/human_9606_b150_GRCh37p13/VCF/common_all_20170710.vcf.gz --output-document="{output}"
        """

rule extract_recode_map:
    input:
        os.path.join("{OUTPUT_DIR}","recode_map","common_all_20170710.vcf.gz")
    output:
        os.path.join("{OUTPUT_DIR}","recode_map","recode_map.txt")
    shell:
        """
        #The zgrep command lets you search the contents of a compressed file without extracting the contents first.
        zgrep -v "^##" "{input}" | cut -f1-3 > "{output}"
        """

rule output_recode_lists:
    input:
        os.path.join("{OUTPUT_DIR}","recode_map","recode_map.txt")
    output:
        os.path.join("{OUTPUT_DIR}", "recode_map", "plink_recode_map.tsv")
    shell:
        """
        #use awk to filter based on the value of a particular column:
        awk '{{print $1":"$2"\t"$3}}' < "{input}" > {output}
    """

rule bgen_to_vcf:
    input:
        bgen=os.path.join("{OUTPUT_DIR}","{SOURCE}","bgen","chr_{CHR}.bgen"),
        sample=lambda wildcards: config['data_dirs'][wildcards.SOURCE]['sample_file'],
        names=os.path.join("{OUTPUT_DIR}", "recode_map", "plink_recode_map.tsv")
    output:
        temp(os.path.join("{OUTPUT_DIR}","{SOURCE}","vcf","chr_{CHR}.vcf"))
    shell:
        """
        out_filename="{output}"
        out_filename="${{out_filename%.*}}"
        # g0m files require snpid-chr argument, g0p files do not
        bgen_arg="{input.bgen} ref-last"
        if [[ {wildcards.SOURCE} == *"g0m"* ]]; then
          bgen_arg="${{bgen_arg}} snpid-chr"
        fi
        plink2 --bgen ${{bgen_arg}} --sample {input.sample} --export vcf --out "${{out_filename}} --update-name {names}"
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
        Rscript ~/.tools/prsice/PRSice.R --prsice ~/.tools/prsice/PRSice_linux --base {input.gwas} --out ${{out_filename}} --snp rsID --no-regress --all-score --fastscore --beta --target ${{bed_prefix}} --extract {input.valid}
        """
