# Take raw data and move it to a temporary location to avoid corrupting it

rule copy_data:
    group:
        "chr_processing"
    input:
        lambda wildcards: os.path.join(config['data_dirs'][wildcards.SOURCE]['bgen_dir'])
    output:
        os.path.join("{OUTPUT_DIR}", "{SOURCE}", "bgen", "chr_{CHR}.bgen")
    shell:
        """
        echo "copy {input}/*chr{wildcards.CHR}.bgen -> {output}"
        cp {input}/*chr{wildcards.CHR}.bgen {output}
        """
