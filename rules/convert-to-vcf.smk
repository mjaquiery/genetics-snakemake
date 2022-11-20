# Convert files

rule bgen_to_vcf:
    group:
        "chr_processing"
    input:
        bgen=os.path.join("{OUTPUT_DIR}", "{SOURCE}", "bgen", "chr_{CHR}_subset.bgen"),
        bgi=os.path.join("{OUTPUT_DIR}", "{SOURCE}", "bgen", "chr_{CHR}_subset.bgen.bgi")
    output:
        os.path.join("{OUTPUT_DIR}", "{SOURCE}", "vcf", "chr_{CHR}.vcf")
    shell:
        """
        bgenix -g {input.bgen} -i {input.bgi} -vcf > {output}
        """

rule make_bgen_index:
    group:
        "chr_processing"
    input:
        os.path.join("{OUTPUT_DIR}", "{SOURCE}", "bgen", "chr_{CHR}_subset.bgen")
    output:
        os.path.join("{OUTPUT_DIR}", "{SOURCE}", "bgen", "chr_{CHR}_subset.bgen.bgi")
    shell:
        """
        bgenix -index -g {input} -clobber
        """
