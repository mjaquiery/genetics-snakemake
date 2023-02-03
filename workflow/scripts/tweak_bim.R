# Take a bim file and:
# - replace CHROM column from input
# - replace ID column with chr:pos:ref:alt
#
library(readr)
library(dplyr)
library(tidyr)
library(stringr)
library(glue)

print("tweak_bim:")

input_file <- commandArgs(T)[2]
chr_number <- commandArgs(T)[3]
output_file <- commandArgs(T)[4]
exclude_id_file <- commandArgs(T)[5]

print(paste("input_file:", input_file))
print(paste("chr_number:", chr_number))
print(paste("output_file:", output_file))
print(paste("exclude_id_file:", exclude_id_file))

col_names <- c("chr", "id", "unknown", "pos", "ref", "alt")

f <- readr::read_tsv(input_file, col_names = col_names)

print("Original format:")
print(f)

set.seed(20230203)

f <- f %>% mutate(
  biallelic = nchar(ref) == 1 & nchar(alt) == 1,
  chr = chr_number,
  id = if_else(biallelic, paste(chr, pos, ref, alt, sep = ":"), paste(chr, pos, sep = "_")),
  id = if_else(biallelic & !pos, glue("unknown_r{runif(1, 0, 1e10)}"), id)
)

print(glue("{f %>% filter(!biallelic) %>% nrow()} multiallelic rows found."))
print(glue("Of which {f %>% filter(str_starts(id, 'unknown_r')) %>% nrow()} are unknown."))
print(glue("Writing multiallelic ids to {exclude_id_file}"))

exclude_list <- f %>% filter(!biallelic) %>% select(id)
readr::write_tsv(exclude_list, exclude_id_file, col_names = F)

f <- f %>% select(-biallelic)

print("New format:")
print(f)

readr::write_tsv(f, output_file, col_names = F)
