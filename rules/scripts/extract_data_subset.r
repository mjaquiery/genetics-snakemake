# Filter ids to only include ones with partner genetic data

# ids linker file is expected to look like:
# source1 source2 source3 ... cidCol
# with cidCol at the end

ids <- read.csv(snakemake$input$link, header=T)
cids <- read.csv(snakemake$input$inc, header=F)

# Take rows where the cid is in cid list, and select appropriate column
ids_ok <- ids[ids[[length(ids)]] %in% cids[[1]], which(names(ids) == snakemake$wildcards$SOURCE]

write(
	paste(ok_ids[[1]], collapse = "\n"),
	paste0(snakemake$wildcards$OUTPUT_DIR, "include_cids_", names(okay_ids)[1], ".txt")
)
