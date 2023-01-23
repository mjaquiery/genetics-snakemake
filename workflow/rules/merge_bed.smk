# Merge .bed files

rule merge_bed:
    input:
        file=os.path.join("{OUTPUT_DIR}", "{SOURCE}", "bed_qc", "chr_22.bed"),
        list=os.path.join("{OUTPUT_DIR}", "{SOURCE}", "mergelist.txt"),
        recode=os.path.join("{OUTPUT_DIR}", "recode_map", "plink_recode_map.tsv")
    output:
        raw=os.path.join("{OUTPUT_DIR}", "{SOURCE}", "all.bed"),
        recoded=os.path.join("{OUTPUT_DIR}", "{SOURCE}", "all_recoded.bed")
    shell:
        """
        in_filename={input.file}
        in_filename=${{in_filename%.*}}
        out_filename={output.raw}
        out_filename=${{out_filename%.*}}
        recoded_filename={output.recoded}
        recoded_filename=${{recoded_filename%.*}}
        echo "Merging .bed files"
        plink2 --bfile ${{in_filename}} --pmerge-list {input.list} --make-bed --out ${{out_filename}} --merge-max-allele-ct 2 --rm-dup --allow-extra-chr
        echo "Recoding merged file"
        plink2 --bfile ${{out_filename}} --update-name {input.recode} --make-bed --out ${{recoded_filename}}
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
            split_targets = [f"{x}.bed {x}.bim {x}.fam" for x in targets]
            print(split_targets)
            list_file.write("\n".join(split_targets))

rule make_recode_lists:
    output:
        os.path.join("{OUTPUT_DIR}", "recode_map", "plink_recode_map.tsv")
    shell:
        """
        DIR="{wildcards.OUTPUT_DIR}/recode_map"
        wget ftp://ftp.ncbi.nih.gov/snp/organisms/human_9606_b150_GRCh37p13/VCF/common_all_20170710.vcf.gz \
            --output-document=$DIR/common_all_20170710.vcf.gz
        #The zgrep command lets you search the contents of a compressed file without extracting the contents first.
        zgrep -v "^##" $DIR/common_all_20170710.vcf.gz | cut - f1 - 3 > $DIR/recode_map.txt

        #use awk to filter based on the value of a particular column:
        awk '{{print $1":"$2"\t"$3}}' < $DIR/recode_map.txt > {output}
    """
