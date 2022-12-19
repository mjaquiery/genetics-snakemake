# Reduce bgen files to only those individuals appearing in valid triads and convert to .bed format

rule extract_id_list:
    input:
        os.path.join("{OUTPUT_DIR}", "complete_triad_ids.tsv")
    output:
        os.path.join("{OUTPUT_DIR}", "triad_ids_{SOURCE}.tsv")
    script:
        "../scripts/extract_id_column.r"

rule subset_bgen:
    group:
        "chr_processing"
    input:
        bgen=os.path.join("{OUTPUT_DIR}", "{SOURCE}", "bgen", "chr_{CHR}.bgen"),
        sample=lambda wildcards: config['data_dirs'][wildcards.SOURCE]['sample_file'],
        ids=os.path.join("{OUTPUT_DIR}", "triad_ids_{SOURCE}.tsv")
    output:
        os.path.join("{OUTPUT_DIR}", "{SOURCE}", "bed", "chr_{CHR}.bed")
    shell:
        """
        echo "Subsetting bgen file {input} -> {output}"
        # module load qctool/2022-04-07-gcc-9.4.0  # we use a local install because the cluster version is broken
        qctool -g {input.bgen} -s {input.sample} -og {output} -incl-samples {input.ids}
        # remove original bgen to conserve disk space
        rm -f {input.bgen}
        """
