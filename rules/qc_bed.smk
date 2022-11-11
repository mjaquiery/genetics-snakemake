# Perform quality control on .bed files

rule qc_bed:
    group:
        "chr_processing"
    input:
        os.path.join("{OUTPUT_DIR}", "{ROLE}", "bed", "chr_{CHR}.bed")
    output:
        os.path.join("{OUTPUT_DIR}", "{ROLE}", "bed_qc", "chr_{CHR}.bed")
    shell:
        """
        plink \
            --bfile {input} \
            --make-bed \
            --maf 0.01 \
            --geno 0.01 \
            --hwe 0.000001 \
            --mind 0.1 \
            --const-fid 0 \
            --rm-dup exclude-all \
            --out {output}
        """
