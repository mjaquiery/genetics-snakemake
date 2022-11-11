# Take raw data and move it to a temporary location to avoid corrupting it

rule copy_data:
    group:
        "chr_processing"
    input:
        lambda wc: os.path.join(config['base_data_path'], config[f'dirname_{wc.ROLE}'], config[f'bgen_path_{wc.ROLE}'])
    output:
        os.path.join("{OUTPUT_DIR}", "{ROLE}", "bgen", "chr_{CHR}.bgen")
    shell:
        """
        cp {input}/*chr{wildcards.CHR}.bgen {output}
        """
