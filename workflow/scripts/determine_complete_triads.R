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
    mutate(source = basename(dirname(id)))
  all_ids <- bind_rows(all_ids, d)
}

print("ID stats:")
all_ids %>% group_by(source) %>% summarise(n = n())

# Valid rows have a role indicator
# F - father
# M - mother
# A - first born child
# B - second born child (for twins)
#
# Limit to valid rows, and split out role and id number
df_in <- all_ids %>%
  mutate(role = str_extract(ID_1, "[FMAB]$")) %>%
  filter(!is.na(role)) %>%
  # handle different id structure for gi_1000g_g0p ids
  mutate(id = map_chr(ID_1, ~ str_remove(., "[FMAB]$")))

print("input:")
print(df_in)

print("ID stats:")
df_in %>% group_by(source, role) %>% summarise(n = n())

# get pregnancy identifier from the linker file
df <- df_in %>%
  mutate(cid = map2_dbl(
    id, source,
    function(id, source) {
      if (id %in% linkfile[[source]])
        as.numeric(linkfile[which(linkfile[[source]] == id), ncol(linkfile)][1])
      else
        -1
    }
  )) %>%
  filter(cid > 0)

print(paste("Dropped", nrow(df_in) - nrow(df), "rows with missing contributor ids"))
print("df:")
print(df)

cids <- df %>%
  nest(data = -cid) %>%
  mutate(entries = map_int(data, nrow))

print("cids:")
print(cids)

print("Family size:")
cids %>% group_by(entries) %>% summarise(n = n())

# Identify complete triads
complete_triads <- cids %>%
  filter(entries > 2)

print("complete_triads:")
print(complete_triads)

id_map <- complete_triads %>%
  unnest(data) %>%
  select(cid, id, source)

print("id_map:")
print(id_map)

print("Summary by file:")
id_map %>% group_by(source) %>% summarise(n = n())

id_map <- id_map %>%
  pivot_wider(
    id_cols = cid,
    names_from = source,
    values_from = id,
    values_fn = unique
  ) %>%
  select(-cid, cid)

print("output:")
print(id_map)

write_tsv(id_map, snakemake@output[[1]])
