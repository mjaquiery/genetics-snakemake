# Genome Wide AssociationS (GWAS) file manipulation
rule clean_gwas:
    resources:
        mem="150G"
    input:
        os.path.join(config['gwas_file'])
    output:
        os.path.join("{OUTPUT_DIR}", "gwas", "gwas-01-clean.tsv")
    shell:
        """
        echo "Cleaning GWAS file {input}"
        # Remove SNPs with low minor allele frequency
        # We use $4 because MAF is the 4th column
        # (This has already been done by the GWAS vendor, but we do it for completness sake)
        awk 'NR==1 || ($4 > 0.01) {{print}}' {input} > {output}

        # Remove SNPs where the lavaan run failed (in-place modification)
        sed -i '/variances/d' {output}
        """

rule deduplicate_gwas:
    resources:
        mem="150G"
    input:
        os.path.join("{OUTPUT_DIR}", "gwas", "gwas-01-clean.tsv")
    output:
        os.path.join("{OUTPUT_DIR}", "gwas", "gwas-02-dedup.tsv")
    shell:
        """
        echo "Deduplicating GWAS file {input}"
        # Remove duplicate SNPs
        # NOTE: Not actually necessary to do this, since original dataset is deduplicated!
        awk '{{seen[$0]++; if(seen[$0]==1){{print}}}}' {input} > {output}
        """

rule disambiguate_gwas:
    resources:
        mem="150G"
    input:
        os.path.join("{OUTPUT_DIR}", "gwas", "gwas-02-dedup.tsv")
    output:
        os.path.join("{OUTPUT_DIR}", "gwas", "gwas-03-disamb.tsv")
    shell:
        """
        echo "Disambiguating GWAS file {input}"
        awk '!( ($4=="A" && $5=="T") || ($4=="T" && $5=="A") || ($4=="G" && $5=="C") || ($4=="C" && $5=="G")) {{print}}' {input} > {output}
        """
