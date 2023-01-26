# Reduce bgen files to only those individuals appearing in valid triads and convert to .bed format

rule extract_id_list:
    input:
        os.path.join("{OUTPUT_DIR}", "complete_triad_ids.tsv")
    output:
        os.path.join("{OUTPUT_DIR}", "triad_ids_{SOURCE}.tsv")
    script:
        "../scripts/extract_id_column.R"

rule subset_bgen:
    group:
        "chr_processing"
    input:
        bgen=os.path.join("{OUTPUT_DIR}", "{SOURCE}", "bgen", "chr_{CHR}.bgen"),
        sample=lambda wildcards: config['data_dirs'][wildcards.SOURCE]['sample_file'],
        ids=os.path.join("{OUTPUT_DIR}", "triad_ids_{SOURCE}.tsv")
    output:
        bgen=os.path.join("{OUTPUT_DIR}", "{SOURCE}", "bed", "chr_{CHR}.bgen"),
        bed=os.path.join("{OUTPUT_DIR}", "{SOURCE}", "bed", "chr_{CHR}.bed")
    shell:
        """
        echo "Subsetting bgen file {input.bgen} -> {output.bgen}"
        echo "Sample file {input.sample}"
        echo "ID whitelist from {input.ids}"
        # module load qctool/2022-04-07-gcc-9.4.0  # we use a local install because the cluster version is broken
        qctool -g {input.bgen} -s {input.sample} -og {output.bgen} -incl-samples {input.ids}
        out_filename={output.bed}
        out_filename=${{out_filename%.*}}
        echo "Converting bgen to bed: {output.bgen} -> {output.bed}"
        plink2 --bgen {output.bgen} ref-unknown --sample {input.sample} --make-bed --out ${{out_filename}} --missing-code -9
        # remove original bgen to conserve disk space
        # rm -f {input.bgen}
        """
