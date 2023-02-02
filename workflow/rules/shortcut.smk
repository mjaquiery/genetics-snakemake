# Calculate Polygenic Risk Scores

rule download_code_map:
    output:
        os.path.join("{OUTPUT_DIR}","recode_map","common_all_20170710.vcf.gz")
    shell:
        """
        wget ftp://ftp.ncbi.nih.gov/snp/organisms/human_9606_b150_GRCh37p13/VCF/common_all_20170710.vcf.gz --output-document="{output}"
        """

rule unzip_code_map:
    input:
        os.path.join("{OUTPUT_DIR}","recode_map","common_all_20170710.vcf.gz")
    output:
        os.path.join("{OUTPUT_DIR}","recode_map","common_all_20170710.vcf")
    shell:
        "gunzip {input}"

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
        map=os.path.join("{OUTPUT_DIR}","recode_map","common_all_20170710.vcf"),
        bgen=os.path.join("{OUTPUT_DIR}","{SOURCE}","bgen","chr_{CHR}.bgen"),
        sample=lambda wildcards: config['data_dirs'][wildcards.SOURCE]['sample_file'],
    params:
        rscript=workflow.source_path("../scripts/recode_chrpos_to_rsid.R")
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
        plink2 --bgen ${{bgen_arg}} --sample {input.sample} --export vcf --out "${{out_filename}}"
        if [[ {wildcards.SOURCE} == *"g0p"* ]]; then
            Rscript "{params.rscript}" --args "{output}" "{input.map}" "{output}"
        fi
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
    priority: 100
    input:
        os.path.join("{OUTPUT_DIR}","{SOURCE}","vcf","filtered_chr_{CHR}.vcf")
    output:
        bed=os.path.join("{OUTPUT_DIR}","{SOURCE}","bed","chr_{CHR}.bed"),
        fam=os.path.join("{OUTPUT_DIR}","{SOURCE}","bed","chr_{CHR}.fam")
    shell:
        """
        out_filename={output.bed}
        out_filename=${{out_filename%.*}}
        plink2 --vcf {input} --make-bed --out "${{out_filename}}"
        """

rule determine_valid_ids:
    input:
        lambda wildcards: expand(
            os.path.join("{OUTPUT_DIR}","{SOURCE}","bed","chr_{i}.fam"),
            i=range(1,23),
            OUTPUT_DIR=wildcards.OUTPUT_DIR,
            SOURCE=wildcards.SOURCE
        )
    output:
        os.path.join("{OUTPUT_DIR}","{SOURCE}","mergelist_ids.txt")
    script:
        "../scripts/find_complete_ids.R"

rule make_mergelist:
    input:
        lambda wildcards: expand(
            os.path.join("{OUTPUT_DIR}","{SOURCE}","bed","chr_{i}.bed"),
            i=range(1, 22),
            OUTPUT_DIR=wildcards.OUTPUT_DIR,
            SOURCE=wildcards.SOURCE
        )  # note we leave off chr_22
    output:
        os.path.join("{OUTPUT_DIR}", "{SOURCE}", "mergelist.txt")
    run:
        print(f"Making mergelist -> {output}")
        import os
        with open(str(output), "w+") as list_file:
            targets = [os.path.splitext(f)[0] for f in input]
            split_targets = [f"{x}.bed {x}.bim {x}.fam" for x in targets]
            print(split_targets)
            list_file.write("\n".join(split_targets))

rule merge_bed:
    input:
        file=os.path.join("{OUTPUT_DIR}", "{SOURCE}", "bed", "chr_22.bed"),
        list=os.path.join("{OUTPUT_DIR}", "{SOURCE}", "mergelist.txt"),
        ids=os.path.join("{OUTPUT_DIR}","{SOURCE}","mergelist_ids.txt")
    output:
        temp(os.path.join("{OUTPUT_DIR}", "{SOURCE}", "all.bed"))
    shell:
        """
        in_filename={input.file}
        in_filename=${{in_filename%.*}}
        out_filename={output}
        out_filename=${{out_filename%.*}}
        echo "Merging .bed files"
        plink2 --bfile ${{in_filename}} --keep {input.ids} --pmerge-list {input.list} --make-bed --out ${{out_filename}}
        echo "QC for merged file"
        plink2 --bfile ${{out_filename}} --maf 0.01 --geno 0.05 --hwe 0.001 --mind 0.05 --make-bed --out ${{recoded_filename}}
        """

rule prs:
    resources:
        mem="150G"
    input:
        bed=os.path.join("{OUTPUT_DIR}", "{SOURCE}", "all.bed"),
        gwas=os.path.join("{OUTPUT_DIR}", "gwas", "gwas-03-disamb.tsv")
    output:
        os.path.join("{OUTPUT_DIR}", "{SOURCE}", "prs.valid")
    shell:
        """
        in_filename={input.bed}
        in_filename=${{in_filename%.*}}
        out_filename={output}
        out_filename=${{out_filename%.*}}
        Rscript ~/.tools/prsice/PRSice.R --prsice ~/.tools/prsice/PRSice_linux --base {input.gwas} --out ${{out_filename}} --snp rsID --no-regress --all-score --fastscore --beta --target ${{in_filename}} || true
        """

rule prs_valid:
    resources:
        mem="150G"
    input:
        bed=os.path.join("{OUTPUT_DIR}", "{SOURCE}", "all.bed"),
        gwas=os.path.join("{OUTPUT_DIR}", "gwas", "gwas-03-disamb.tsv"),
        valid=os.path.join("{OUTPUT_DIR}", "{SOURCE}", "prs.valid")
    output:
        os.path.join("{OUTPUT_DIR}", "{SOURCE}", "prs.all_score")
    shell:
        """
        in_filename={input.bed}
        in_filename=${{in_filename%.*}}
        out_filename={output}
        out_filename=${{out_filename%.*}}
        Rscript ~/.tools/prsice/PRSice.R --prsice ~/.tools/prsice/PRSice_linux --base {input.gwas} --out ${{out_filename}} --snp rsID --no-regress --all-score --fastscore --beta --target ${{in_filename}} --extract {input.valid}
        """
