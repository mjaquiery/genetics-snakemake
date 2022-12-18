# Take raw data and move it to a temporary location to avoid corrupting it

rule make_data:
    output:
        os.path.join("hiworld.txt")
    shell:
        """
        echo "writing to file"
        echo "hello, world" > {output}
        """

rule hi_world:
    input:
        os.path.join("hiworld.txt")
    output:
        os.path.join("{OUTPUT_DIR}", "hiworld_{CHR}.txt")
    shell:
        """
        echo "copying file"
        cp {input} {output}
        echo "taking a nap"
        sleep 30
        """

rule rversion:
    input:
        os.path.join("{OUTPUT_DIR}", "hiworld_{CHR}.txt")
    output:
        os.path.join("{OUTPUT_DIR}", "rver_{CHR}.txt")
    conda:
        "../envs/environment.yaml"
    envmodules:
        "r/4.1.1-gcc-9.4.0"
    shell:
        "Rscript --version >> {output}"

rule rtest:
    input:
        os.path.join("{OUTPUT_DIR}", "rver_{CHR}.txt")
    output:
        os.path.join("{OUTPUT_DIR}", "r_{CHR}.txt")
    conda:
        "../envs/environment.yaml"
    envmodules:
        "r/4.1.1-gcc-9.4.0"
    script:
        "../scripts/test.R"

"""
Test with:
snakemake --cores 1 results/slurmtest/byeworld_22.txt
Or:
snakemake --cores 1 test
"""