# Filter ids to only include ones with partner genetic data

# ids linker file is expected to look like:
# source1 source2 source3 ... cidCol
# with cidCol at the end
#
# output will be a similarly structured file with only complete triads retained
library(readr)  # for read_tsv

print("extract_column_id:")
print(paste("snakemake@input:", snakemake@input[[1]]))
print(paste("snakemake@wildcards$SOURCE:", snakemake@wildcards$SOURCE))

triads <- snakemake@input[[1]]
column <- snakemake@wildcards$SOURCE

# read in data
id_map <- read_tsv(triads, col_names = T)

# find our column
ids <- id_map[[column]]

# Valid rows have a role indicator
# F - father
# M - mother
# A - first born child
# B - second born child (for twins)
#
# Here we expand basic ids to allow for them to match any role
out <- sapply(ids, function(id) unlist(paste0(id, c("M", "F", "A", "B"))))
out <- c(out[1,], out[2,], out[3,], out[4,])

write(out, file = snakemake@output[[1]])
