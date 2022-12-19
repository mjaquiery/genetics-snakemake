# Determine IDs that form part of a triad with partners who have genetic data
rule determine_complete_triads:
    input:
        ids=[config['data_dirs'][d]['sample_file'] for d in config['data_dirs']],
        link=os.path.join(config['linker_file'])
    output:
        os.path.join("{OUTPUT_DIR}","complete_triad_ids.tsv")
    script:
        "../scripts/determine_complete_triads.R"
