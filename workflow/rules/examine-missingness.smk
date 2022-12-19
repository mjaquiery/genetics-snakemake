# Identify the proportion of genetic information missing in samples

rule find_missing:
    group:
        "chr_processing"
    input:
        os.path.join("{OUTPUT_DIR}", "{SOURCE}", "bed", "chr_{CHR}.bed")
    output:
        os.path.join("{OUTPUT_DIR}", "{SOURCE}", "miss", "chr_{CHR}.imiss")
    shell:
        """
        filename={input}
        filename=${{filename%.*}}
        plink --bed {input} --out ${{filename}} --const-fid 0 --missing
        """

rule generate_missingness_report:
    input:
        lambda wildcards: expand(
            os.path.join("{OUTPUT_DIR}", "{SOURCE}", "miss", "chr_{i}.imiss"),
            i=range(1, 23),
            OUTPUT_DIR=wildcards.OUTPUT_DIR,
            SOURCE=wildcards.SOURCE
        )
    output:
        os.path.join("{OUTPUT_DIR}", "reports", "{SOURCE}_missingness.csv")
    script: "scripts/generate_missingness_report.R"
