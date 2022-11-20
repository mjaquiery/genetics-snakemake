# Take raw data and move it to a temporary location to avoid corrupting it

rule copy_data:
    group:
        "chr_processing"
    input:
        lambda wc: os.path.join(config['data_dirs'][wc.SOURCE]['bgen_dir'])
    output:
        os.path.join("{OUTPUT_DIR}", "{SOURCE}", "bgen", "chr_{CHR}.bgen")
    shell:
        """
        cp {input}/*chr{wildcards.CHR}.bgen {output}
        """
