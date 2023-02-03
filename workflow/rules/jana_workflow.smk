# Calculate Polygenic Risk Scores

# Determine IDs that form part of a triad with partners who have genetic data
rule determine_complete_triads:
    input:
        ids=[config['data_dirs'][d]['sample_file'] for d in config['data_dirs']],
        link=os.path.join(config['linker_file'])
    output:
        os.path.join("{OUTPUT_DIR}","complete_triad_ids.tsv")
    script:
        "../scripts/determine_complete_triads.R"

rule extract_id_list:
    input:
        os.path.join("{OUTPUT_DIR}","complete_triad_ids.tsv")
    output:
        os.path.join("{OUTPUT_DIR}","triad_ids_{SOURCE}.tsv")
    script:
        "../scripts/extract_id_column.R"

rule subset_by_ids:
    input:
        bgen=os.path.join("{OUTPUT_DIR}", "{SOURCE}", "bgen", "chr_{CHR}.bgen"),
        sample=lambda wildcards: config['data_dirs'][wildcards.SOURCE]['sample_file'],
        ids=os.path.join("{OUTPUT_DIR}", "triad_ids_{SOURCE}.tsv")
    output:
        temp(os.path.join("{OUTPUT_DIR}", "{SOURCE}", "bgen", "filtered_chr_{CHR}.bgen"))
    shell:
        """
        echo "Subsetting bgen file {input.bgen} -> {output}"
        echo "Sample file {input.sample}"
        echo "ID whitelist from {input.ids}"
        # module load qctool/2022-04-07-gcc-9.4.0  # we use a local install because the cluster version is broken
        qctool -g {input.bgen} -s {input.sample} -og {output} -incl-samples {input.ids}
        """

rule subset_sample_file:
    input:
        sample=lambda wildcards: config['data_dirs'][wildcards.SOURCE]['sample_file'],
        include_ids=os.path.join("{OUTPUT_DIR}", "triad_ids_{SOURCE}.tsv")
    output:
        os.path.join("{OUTPUT_DIR}","{SOURCE}", "bgen", "trimmed.sample")
    script:
        "../scripts/filter_sample.R"

rule bgen_to_bed:
    input:
        bgen=os.path.join("{OUTPUT_DIR}", "{SOURCE}", "bgen", "chr_{CHR}.bgen"),
        sample=lambda wildcards: config['data_dirs'][wildcards.SOURCE]['sample_file'],
        ids=os.path.join("{OUTPUT_DIR}", "triad_ids_{SOURCE}.tsv")
    output:
        bed=os.path.join("{OUTPUT_DIR}","{SOURCE}","bed","chr_{CHR}.bed"),
        bim=os.path.join("{OUTPUT_DIR}","{SOURCE}","bed","chr_{CHR}.bim"),
        fam=os.path.join("{OUTPUT_DIR}","{SOURCE}","bed","chr_{CHR}.fam")
    shell:
        """
        out_filename="{output.bed}"
        out_filename="${{out_filename%.*}}"
        plink2 --bgen {input.bgen} ref-last --sample {input.sample} --keep {input.ids} --make-bed --out "${{out_filename}}"
        """

rule clean_bim:
    priority: 100
    input:
        os.path.join("{OUTPUT_DIR}", "{SOURCE}", "bed", "chr_{CHR}.bim")
    params:
        rscript=workflow.source_path("../scripts/tweak_bim.R")
    output:
        os.path.join("{OUTPUT_DIR}", "{SOURCE}", "bed", "exclude_snps_{CHR}.txt")
    shell:
        """
        Rscript "{params.rscript}" --args "{input}" "{wildcards.CHR}" "{input}.x" "{output}"
        """

rule filter_variants:
    input:
        bed=os.path.join("{OUTPUT_DIR}","{SOURCE}","bed","chr_{CHR}.bed"),
        exclude=os.path.join("{OUTPUT_DIR}", "{SOURCE}", "bed", "exclude_snps_{CHR}.txt")
    output:
        os.path.join("{OUTPUT_DIR}","{SOURCE}","bed","biallelic_chr_{CHR}.bed")
    shell:
        """
        in_filename="{input.bed}"
        in_filename="${{in_filename%.*}}"
        out_filename="{output}"
        out_filename="${{out_filename%.*}}"
        plink2 --bfile "${{in_filename}}" --make-bed --exclude "{input.exclude}" --out "${{out_filename}}"
        """


rule make_mergelist:
    input:
        lambda wildcards: expand(
            os.path.join("{OUTPUT_DIR}","{SOURCE}","bed","biallelic_chr_{i}.bed"),
            i=range(1, 23),
            OUTPUT_DIR=wildcards.OUTPUT_DIR,
            SOURCE=wildcards.SOURCE
        )
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
        os.path.join("{OUTPUT_DIR}", "{SOURCE}", "mergelist.txt")
    output:
        os.path.join("{OUTPUT_DIR}", "{SOURCE}", "all.bed")
    shell:
        """
        out_filename={output}
        out_filename=${{out_filename%.*}}
        echo "Merging .bed files"
        plink --merge-list "{input}" --make-bed --out "${{out_filename}}" --snps-only 'just-acgt' --maf 0.01 --geno 0.05 --hwe 0.001 --mind 0.05
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
        out_filename={output}
        out_filename=${{out_filename%.*}}
        Rscript ~/.tools/prsice/PRSice.R --prsice ~/.tools/prsice/PRSice_linux --base {input.gwas} --out ${{out_filename}} --snp rsID --no-regress --all-score --fastscore --beta --target {input.bed} || true
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
        out_filename={output}
        out_filename=${{out_filename%.*}}
        Rscript ~/.tools/prsice/PRSice.R --prsice ~/.tools/prsice/PRSice_linux --base {input.gwas} --out ${{out_filename}} --snp rsID --no-regress --all-score --fastscore --beta --target {input.bed} --extract {input.valid}
        """
