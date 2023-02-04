# Take a bim file and use chr:pos + variant info to recode from a mapper file
#
library(readr)
library(dplyr)
library(tidyr)
library(stringr)
library(glue)

print("recode_bim_to_rsid:")

input_file <- commandArgs(T)[2]
map_file <- commandArgs(T)[3]
output_file <- commandArgs(T)[4]

print(paste("input_file:", input_file))
print(paste("map_file:", map_file))
print(paste("output_file:", output_file))

col_names <- c("CHROM", "ID", "unknown", "POS", "REF", "ALT")

f <- readr::read_tsv(input_file, col_names = col_names)

print("Original format:")
print(f)

map <- readr::read_delim(
  map_file,
  delim = "\t",
  comment = "#",
  col_names = c("CHROM", "POS", "ID", "REF", "ALT", "QUAL", "FILTER", "INFO"),
  col_types = cols(.default = col_character())
) %>%
  select(CHROM, POS, rsID = ID, REF, ALT) %>%
  filter(CHROM %in% chr_whitelist)

print("Mapper structure:")
print(map)

f <- left_join(f, map, by = c("CHROM", "POS", "REF", "ALT"))

print("Joined structure:")
print(f)

f <- f %>% mutate(ID = rsID) %>% select(everything(), -rsID)

print("Converted structure:")
print(f)

print("Handling swapped ref/alt alleles")
na <- f %>% filter(is.na(ID))
f <- f %>% filter(!is.na(ID))

print("OKAY rows:")
print(f)

na <- na %>%
  mutate(tmp = REF, REF = ALT, ALT = tmp) %>%
  select(-tmp)

print("NA rows:")
print(na)

na <- left_join(na, map, by = c("CHROM", "POS", "REF", "ALT"))
na <- na %>% mutate(ID = rsID) %>% select(everything(), -rsID)

f <- bind_rows(f, na) %>% arrange(POS)

print("Output:")
print(f)

na <- na %>% filter(is.na(ID))
if (nrow(na)) {
  print(glue("{nrow(f %>% filter(is.na(ID)))} rows with NA ID"))
  print(na)
}

readr::write_tsv(f, output_file, col_names = F)

print("Wrote new bim file")
