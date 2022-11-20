# Determine IDs that form part of a triad with partners who have genetic data
rule extract_subset:
    input:
        link=os.path.join(config['linker_file']),
        inc=os.path.join(config['include_cids_file'])
    output:
        os.path.join("{OUTPUT_DIR}", "include_cids_{SOURCE}.txt")
    script: "scripts/extract_data_subset.r"
