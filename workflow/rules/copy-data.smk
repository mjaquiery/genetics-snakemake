# Take raw data and move it to a temporary location to avoid corrupting it

rule copy_data:
    group:
        "chr_processing"
    input:
        lambda wc: glob_wildcards(os.path.join(config['data_dirs'][wc.SOURCE]['bgen_dir']), f"*chr_?0?{wc.CHR}.bgen")
    output:
        os.path.join("{OUTPUT_DIR}", "{SOURCE}", "bgen", "chr_{CHR}.bgen")
    shell:
        """
        echo "copy {input}/*chr{wildcards.CHR}.bgen -> {output}"
        cp {input}/*chr{wildcards.CHR}.bgen {output}
        """
