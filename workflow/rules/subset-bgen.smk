# Reduce bgen files to only those individuals appearing in valid triads and convert to .bed format

rule extract_id_list:
    input:
        os.path.join("{OUTPUT_DIR}", "complete_triad_ids.tsv")
    output:
        os.path.join("{OUTPUT_DIR}", "triad_ids_{SOURCE}.tsv")
    script:
        "../scripts/extract_id_column.R"

rule subset_by_ids:
    group:
        "chr_processing"
    input:
        bgen=os.path.join("{OUTPUT_DIR}", "{SOURCE}", "bgen", "chr_{CHR}.bgen"),
        sample=lambda wildcards: config['data_dirs'][wildcards.SOURCE]['sample_file'],
        ids=os.path.join("{OUTPUT_DIR}", "triad_ids_{SOURCE}.tsv")
    output:
        temp(os.path.join("{OUTPUT_DIR}", "{SOURCE}", "vcf", "chr_{CHR}.vcf"))
    shell:
        """
        echo "Subsetting bgen file {input.bgen} -> {output}"
        echo "Sample file {input.sample}"
        echo "ID whitelist from {input.ids}"
        # module load qctool/2022-04-07-gcc-9.4.0  # we use a local install because the cluster version is broken
        qctool -g {input.bgen} -s {input.sample} -og {output} -incl-samples {input.ids}
        """

rule repair_vcf:
    input:
        vcf=os.path.join("{OUTPUT_DIR}", "{SOURCE}", "vcf", "chr_{CHR}.vcf")
    output:
        vcf=temp(os.path.join("{OUTPUT_DIR}", "{SOURCE}", "vcf", "fixed_chr_{CHR}.vcf"))
    script:
        "../scripts/repair_qctool_vcf.R"

rule convert_to_bed:
    group:
        "chr_processing"
    input:
        os.path.join("{OUTPUT_DIR}", "{SOURCE}", "vcf", "fixed_chr_{CHR}.vcf")
    output:
        os.path.join("{OUTPUT_DIR}", "{SOURCE}", "bed", "chr_{CHR}.bed")
    shell:
        """
        out_filename={output}
        out_filename=${{out_filename%.*}}
        # echo "Converting bgen to bed: {input} -> {output}"
        plink2 --vcf {input} --make-bed --out ${{out_filename}}
        """

