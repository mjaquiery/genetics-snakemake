# Determine IDs that form part of a triad with partners who have genetic data
rule extract_subset:
    input:
        link=os.path.join(config['base_data_path'], config['path_to_link_ids']),
        partner=os.path.join(config['base_data_path'], config['dirname_partner'], config['path_to_partner_ids'])
    output:
        partner=os.path.join("{OUTPUT_DIR}", "ids", "path_to_subset_partner_ids.txt"),
        child=os.path.join("{OUTPUT_DIR}", "ids", "path_to_subset_child_ids.txt"),
        mother=os.path.join("{OUTPUT_DIR}", "ids", "path_to_subset_mother_ids.txt")
    script: "scripts/extract_data_subset.r"
