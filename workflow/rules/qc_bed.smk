# Perform quality control on .bed files

rule qc_bed:
    group:
        "chr_processing"
    input:
        bed=os.path.join("{OUTPUT_DIR}", "{SOURCE}", "bed", "chr_{CHR}.bed"),
        recode=os.path.join("{OUTPUT_DIR}", "recode_map", "plink_recode_map.tsv")
    output:
        raw=os.path.join("{OUTPUT_DIR}", "{SOURCE}", "bed_qc", "chr_{CHR}.bed"),
        recoded=os.path.join("{OUTPUT_DIR}", "{SOURCE}", "recoded_chr_{CHR}.bed")
    shell:
        """
        in_filename={input.bed}
        in_filename=${{in_filename%.*}}
        out_filename={output.raw}
        out_filename=${{out_filename%.*}}
        recoded_filename={output.recoded}
        recoded_filename=${{recoded_filename%.*}}
        echo "Quality controlling {input} -> {output}"
        plink \
            --bfile ${{in_filename}} \
            --make-bed \
            --biallelic-only list \
            --set-missing-var-ids @:#\$1,\$2 \
            --maf 0.01 \
            --geno 0.01 \
            --hwe 0.000001 \
            --mind 0.1 \
            --const-fid 0 \
            --out ${{out_filename}} \
            --allow-extra-chr  # required to avoid Error: Invalid chromosome code 'NA' on line 1 of .bim file.
        echo "Recoding file"
        plink2 --bfile ${{out_filename}} --update-name {input.recode} --make-bed --out ${{recoded_filename}}
        """

# --biallelic-only to avoid downstream errors about 3+ alleles
# --set-missing-var-ids @:#\$1,\$2 to rename missing ids
# --allow-extra-chr required to avoid Error: Invalid chromosome code 'NA' on line 1 of .bim file.


rule make_recode_lists:
    output:
        os.path.join("{OUTPUT_DIR}", "recode_map", "plink_recode_map.tsv")
    shell:
        """
        DIR="{wildcards.OUTPUT_DIR}/recode_map"
        wget ftp://ftp.ncbi.nih.gov/snp/organisms/human_9606_b150_GRCh37p13/VCF/common_all_20170710.vcf.gz \
            --output-document="$DIR/common_all_20170710.vcf.gz"
        #The zgrep command lets you search the contents of a compressed file without extracting the contents first.
        zgrep -v "^##" "$DIR/common_all_20170710.vcf.gz" | cut -f1-3 > "$DIR/recode_map.txt"

        #use awk to filter based on the value of a particular column:
        awk '{{print $1":"$2"\t"$3}}' < "$DIR/recode_map.txt" > {output}
    """