# Merge .bed files

rule merge_bed:
    input:
        file=os.path.join("{OUTPUT_DIR}", "{SOURCE}", "bed_qc", "chr_22.bed"),
        list=os.path.join("{OUTPUT_DIR}", "{SOURCE}", "mergelist.txt")
    output:
        os.path.join("{OUTPUT_DIR}", "{SOURCE}", "all.bed")
    shell:
        """
        plink --bfile {input.file} --merge-list {input.list} --make-bed --out {output}
        """

rule make_mergelist:
    input:
        lambda wildcards: expand(
            os.path.join("{OUTPUT_DIR}","{SOURCE}","bed_qc","chr_{i}.bed"),
            i=range(1, 22),
            OUTPUT_DIR=wildcards.OUTPUT_DIR,
            SOURCE=wildcards.SOURCE
        )  # note we leave off chr_22
    output:
        os.path.join("{OUTPUT_DIR}", "{SOURCE}", "mergelist.txt")
    run:
        import os
        with open(output, "w+") as list_file:
            for f in input:
                list_file.write(os.path.splitext(f)[0])
