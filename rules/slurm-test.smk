# Take raw data and move it to a temporary location to avoid corrupting it

rule make_data:
    output:
        os.path.join(config['raw_data_dir'], "hiworld.txt")
    shell:
        """
        echo "hello, world" > {output}
        """

rule copy_data:
    input:
        os.path.join(config['raw_data_dir'], "hiworld.txt")
    output:
        os.path.join("{OUTPUT_DIR}", "slurmtest", "hiworld_{CHR}.txt")
    shell:
        """
        cp {input} {output}
        sleep 30
        """

"""
Test with:
snakemake --cores 1 results/slurmtest/hiworld_22.txt
"""