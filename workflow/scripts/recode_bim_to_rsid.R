# Take a bim file and use chr:pos + variant info to recode from a mapper file
#
library(tidyverse)
library(glue)

print("recode_bim_to_rsid:")

input_file <- commandArgs(T)[2]
map_file <- commandArgs(T)[3]
gwas_file <- commandArgs(T)[4]
output_file <- commandArgs(T)[5]

print(paste("input_file:", input_file))
print(paste("map_file:", map_file))
print(paste("gwas_file:", gwas_file))
print(paste("output_file:", output_file))

col_names <- c("CHROM", "ID", "unknown", "POS", "REF", "ALT")

f <- readr::read_tsv(input_file, col_names = col_names, col_types = 'iciicc')

print("Original format:")
f

required_row_size <- nrow(f)

map <- readr::read_tsv(
  map_file,
  comment = "#",
  col_names = c("CHROM", "POS", "ID", "REF", "ALT", "QUAL", "FILTER", "INFO"),
  col_types = 'cicccccc'
) %>%
  filter(str_detect(CHROM, "\\d")) %>%
  mutate(CHROM = as.integer(CHROM)) %>%
  select(CHROM, POS, rsID = ID, REF, ALT)

print("Mapper structure:")
print(map)

gwas <- readr::read_tsv(gwas_file)

print("Mapper after non-gwas rsIDs removed:")
map <- map %>% filter(rsID %in% gwas$rsID)
print(glue("{map %>% nrow()} rows remaining"))
print("Removing rsIDs with same chr:pos:ref:alt")
map <- map %>%
  nest(data = rsID) %>%
  mutate(row_count = map_int(data, nrow)) %>%
  filter(row_count == 1) %>%
  unnest(data) %>%
  select(-row_count)
print(glue("{map %>% nrow()} rows remaining"))

f <- left_join(f, map, by = c("CHROM", "POS", "REF", "ALT"))

assertthat::assert_that(nrow(f) == row_count)

print("Joined structure:")
f

f <- f %>% mutate(ID = rsID) %>% select(everything(), -rsID)

print("Converted structure:")
f

print("Handling swapped ref/alt alleles")
f <- f %>% mutate(
  tmp = REF,
  REF = if_else(is.na(ID), ALT, REF),
  ALT = if_else(is.na(ID), tmp, ALT)
) %>%
  select(-tmp)

print(glue("OKAY rows: {f %>% filter(!is.na(ID)) %>% nrow()}"))
print(glue("Trying swap for {f %>% filter(is.na(ID)) %>% nrow()} rows."))

f <- left_join(f, map, by = c("CHROM", "POS", "REF", "ALT"))
assertthat::assert_that(nrow(f) == row_count)

f <- f %>%
  mutate(ID = if_else(is.na(ID), rsID, ID)) %>%
  select(everything(), -rsID)

print("Output:")
f

print("Summary:")
f %>%
  mutate(na_id = is.na(ID)) %>%
  group_by(na_id) %>%
  summarise(n = n())

readr::write_tsv(f, output_file, col_names = F)

print("Wrote new bim file")
