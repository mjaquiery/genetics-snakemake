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
        in_filename=basename "{input}" .bed
        out_filename=basename "{output}" .bed
        echo "Quality controlling {input} -> {output}"
        plink \
            --bfile ${{in_filename}} \
            --make-bed \
            --maf 0.01 \
            --geno 0.01 \
            --hwe 0.000001 \
            --mind 0.1 \
            --const-fid 0 \
            --out ${{out_filename}}
        """
