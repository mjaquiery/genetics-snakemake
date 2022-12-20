# Perform quality control on .bed files

rule qc_bed:
    group:
        "chr_processing"
    input:
        os.path.join("{OUTPUT_DIR}", "{SOURCE}", "bed", "chr_{CHR}.bed")
    output:
        os.path.join("{OUTPUT_DIR}", "{SOURCE}", "bed_qc", "chr_{CHR}.bed")
    shell:
        """
        in_filename={input}
        in_filename=${{in_filename%.*}}
        out_filename={output}
        out_filename=${{out_filename%.*}}
        echo "Quality controlling {input} -> {output}"
        plink \
            --bfile ${{in_filename}} \
            --make-bed \
            # biallelic only to avoid downstream errors about 3+ alleles
            --biallelic-only \
            --maf 0.01 \
            --geno 0.01 \
            --hwe 0.000001 \
            --mind 0.1 \
            --const-fid 0 \
            --out ${{out_filename}} \
            --allow-extra-chr  # required to avoid Error: Invalid chromosome code 'NA' on line 1 of .bim file.
        """
