# Run a simple workflow test that will ensure we have snakemake and R available

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

rule shelldump:
    input:
        os.path.join("{OUTPUT_DIR}", "hiworld_{CHR}.txt")
    output:
        os.path.join("{OUTPUT_DIR}", "sh_{CHR}.txt")
    shell:
        """
        echo $0 >> output.txt
        echo $PATH >> output.txt
        echo pwd >> output.txt
        which conda >> output.txt
        which module >> output.txt
        cp output.txt {output}
        """

rule rversion:
    input:
        os.path.join("{OUTPUT_DIR}", "sh_{CHR}.txt")
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
