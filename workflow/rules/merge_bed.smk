# Merge .bed files

rule merge_bed:
    input:
        file=os.path.join("{OUTPUT_DIR}", "{SOURCE}", "bed_qc", "chr_22.bed"),
        list=os.path.join("{OUTPUT_DIR}", "{SOURCE}", "mergelist.txt")
    output:
        os.path.join("{OUTPUT_DIR}", "{SOURCE}", "all.bed")
    shell:
        """
        in_filename={input.file}
        in_filename=${{in_filename%.*}}
        out_filename={output}
        out_filename=${{out_filename%.*}}
        echo "Merging .bed files"
        plink --bfile ${{in_filename}} --merge-list {input.list} --make-bed --biallelic-only --set-missing-var-ids @:#\$1,\$2 --out ${{out_filename}} --allow-extra-chr
        """

rule make_mergelist:
    input:
        lambda wildcards: expand(
            os.path.join("{OUTPUT_DIR}","{SOURCE}","bed_qc","chr_{i}.bed"),
            i=[x for x in range(1, 22) if x != 8],  # skip chr 8 while it's corrupted!
            OUTPUT_DIR=wildcards.OUTPUT_DIR,
            SOURCE=wildcards.SOURCE
        )  # note we leave off chr_22
    output:
        os.path.join("{OUTPUT_DIR}", "{SOURCE}", "mergelist.txt")
    run:
        print(f"Making mergelist -> {output}")
        import os
        with open(str(output), "w+") as list_file:
            targets = [os.path.splitext(f)[0] for f in input]
            print(targets)
            list_file.write("\n".join(targets))
