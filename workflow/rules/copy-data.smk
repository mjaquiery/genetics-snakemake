# Take raw data and move it to a temporary location to avoid corrupting it

rule copy_data:
    group:
        "chr_processing"
    input:
        os.path.join(config['raw_data_dir'])
    output:
        os.path.join("{OUTPUT_DIR}", "bgen", "chr_{CHR}.bgen")
    shell:
        """
        
        cp {input} {output}
        """

"""
Test with:
snakemake --cores 1 results/g0p/hiworld_22.txt
"""