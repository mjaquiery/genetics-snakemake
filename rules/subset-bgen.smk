# Reduce bgen files to only those individuals appearing in valid triads and convert to .bed format

rule subset_bgen:
    group:
        "chr_processing"
    input:
        bgen=os.path.join("{OUTPUT_DIR}", "{ROLE}", "bgen", "chr_{CHR}.bgen"),
        sample=lambda wc: os.path.join(config['base_data_path'], config[f'dirname_{wc.ROLE}'], config[f'path_to_{wc.ROLE}_ids']),
        ids=os.path.join("{OUTPUT_DIR}", "ids", "path_to_subset_{ROLE}_ids.txt")
    output:
        os.path.join("{OUTPUT_DIR}", "{ROLE}", "bed", "chr_{CHR}.bed")
    shell:
        """
        qctool -g {input.bgen} -s {input.sample} -og {output} -incl-samples {input.ids}
        # remove original bgen to conserve disk space
        rm -f {input.bgen}
        """
