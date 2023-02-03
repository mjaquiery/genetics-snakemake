# Calculate Polygenic Risk Scores

rule bgen_to_bed:
    input:
        bgen=os.path.join("{OUTPUT_DIR}","{SOURCE}","bgen","chr_{CHR}.bgen"),
        sample=lambda wildcards: config['data_dirs'][wildcards.SOURCE]['sample_file'],
    output:
        bed=os.path.join("{OUTPUT_DIR}","{SOURCE}","bed","chr_{CHR}.bed"),
        bim=os.path.join("{OUTPUT_DIR}","{SOURCE}","bed","chr_{CHR}.bim"),
        fam=os.path.join("{OUTPUT_DIR}","{SOURCE}","bed","chr_{CHR}.fam")
    shell:
        """
        out_filename="{output.bed}"
        out_filename="${{out_filename%.*}}"
        plink2 --bgen ${{out_filename}} ref-last --sample {input.sample} --make-bed --out "${{out_filename}}"
        """

rule clean_bim:
    priority: 100
    input:
        os.path.join("{OUTPUT_DIR}", "{SOURCE}", "bed", "chr_{CHR}.bim")
    params:
        rscript=workflow.source_path("../scripts/recode_chrpos_to_rsid.R")
    output:
        os.path.join("{OUTPUT_DIR}", "{SOURCE}", "bed", "cleaned_{CHR}")
    shell:
        """
        Rscript "{params.rscript}" --args "{input}" "{wildcards.CHR}" "{output}"
        touch {output}
        """

rule make_mergelist:
    input:
        lambda wildcards: expand(
            os.path.join("{OUTPUT_DIR}","{SOURCE}","bed","stripped_chr_{i}.bed"),
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
        file=os.path.join("{OUTPUT_DIR}", "{SOURCE}", "bed", "stripped_chr_22.bed"),
        list=os.path.join("{OUTPUT_DIR}", "{SOURCE}", "mergelist.txt")
    output:
        os.path.join("{OUTPUT_DIR}", "{SOURCE}", "all.bed")
    shell:
        """
        in_filename={input.file}
        in_filename=${{in_filename%.*}}
        out_filename={output}
        out_filename=${{out_filename%.*}}
        echo "Merging .bed files"
        plink2 --bfile ${{in_filename}} --pmerge-list {input.list} --make-bed --out ${{out_filename}}
        echo "QC for merged file"
        plink2 --bfile ${{out_filename}} --maf 0.01 --geno 0.05 --hwe 0.001 --mind 0.05 --make-bed --out ${{recoded_filename}}
        """

rule prs:
    resources:
        mem="150G"
    input:
        bed=lambda wildcards: expand(
            os.path.join("{OUTPUT_DIR}","{SOURCE}","bed","stripped_chr_{i}.bed"),
            i=range(1,23),
            OUTPUT_DIR=wildcards.OUTPUT_DIR,
            SOURCE=wildcards.SOURCE
        ),
        gwas=os.path.join("{OUTPUT_DIR}", "gwas", "gwas-03-disamb.tsv")
    output:
        os.path.join("{OUTPUT_DIR}", "{SOURCE}", "prs.valid")
    shell:
        """
        bed_prefix="{wildcards.OUTPUT_DIR}/{wildcards.SOURCE}/bed/stripped_chr_#"
        out_filename={output}
        out_filename=${{out_filename%.*}}
        Rscript ~/.tools/prsice/PRSice.R --prsice ~/.tools/prsice/PRSice_linux --base {input.gwas} --out ${{out_filename}} --snp rsID --no-regress --all-score --fastscore --beta --target ${{bed_prefix}} || true
        """

rule prs_valid:
    resources:
        mem="150G"
    input:
        bed=lambda wildcards: expand(
            os.path.join("{OUTPUT_DIR}","{SOURCE}","bed","stripped_chr_{i}.bed"),
            i=range(1,23),
            OUTPUT_DIR=wildcards.OUTPUT_DIR,
            SOURCE=wildcards.SOURCE
        ),
        gwas=os.path.join("{OUTPUT_DIR}", "gwas", "gwas-03-disamb.tsv"),
        valid=os.path.join("{OUTPUT_DIR}", "{SOURCE}", "prs.valid")
    output:
        os.path.join("{OUTPUT_DIR}", "{SOURCE}", "prs.all_score")
    shell:
        """
        bed_prefix="{wildcards.OUTPUT_DIR}/{wildcards.SOURCE}/bed/stripped_chr_#"
        out_filename={output}
        out_filename=${{out_filename%.*}}
        Rscript ~/.tools/prsice/PRSice.R --prsice ~/.tools/prsice/PRSice_linux --base {input.gwas} --out ${{out_filename}} --snp rsID --no-regress --all-score --fastscore --beta --target ${{bed_prefix}} --extract {input.valid}
        """
