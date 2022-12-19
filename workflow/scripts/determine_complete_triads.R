# Filter ids to only include ones with partner genetic data

# ids linker file is expected to look like:
# source1 source2 source3 ... cidCol
# with cidCol at the end
#
# output will be a similarly structured file with only complete triads retained
library(readr)
library(tibble)
library(dplyr)
library(purrr)
library(tidyr)
library(stringr)

print("determine_complete_triads:")
print(paste("snakemake@input$ids:", snakemake@input$ids))
print(paste("snakemake@input$link:", snakemake@input$link))

ids <- snakemake@input$ids
link <- snakemake@input$link

# read in data
linkfile <- read.csv(link) %>% as_tibble()
all_ids <- tibble()

for (id in ids) {
  d <- read_delim(id, delim = " ") %>%
    as_tibble() %>%
    mutate(source = dirname(id))
  all_ids <- bind_rows(all_ids, d)
}

# Valid rows have a role indicator
# F - father
# M - mother
# A - first born child
# B - second born child (for twins)
#
# Limit to valid rows, and split out role and id number
df <- all_ids %>%
  mutate(role = str_extract(ID_1, "[FMAB]$")) %>%
  filter(!is.na(role)) %>%
  mutate(id = str_extract(ID_1, "\\d+")) %>%
  mutate(id = as.numeric(id))

# get pregnancy identifier from the linker file
df <- df %>%
  mutate(cid = map2_dbl(
    id, source,
    function(id, source) {
      if (id %in% linkfile[[source]])
        as.numeric(linkfile[linkfile[[source]] == id, ncol(linkfile)][1])
      else
        -1
    }
  ))

cids <- df %>% nest(data = -cid)

# Identify complete triads
complete_triads <- cids %>%
  mutate(entries = map_int(data, nrow)) %>%
  filter(entries > 2)

id_map <- complete_triads %>%
  unnest(data) %>%
  select(cid, id, source) %>%
  pivot_wider(
    id_cols = cid,
    names_from = source,
    values_from = id,
    values_fn = unique
  ) %>%
  select(-cid, cid)

write_tsv(id_map, snakemake@output[[1]])
