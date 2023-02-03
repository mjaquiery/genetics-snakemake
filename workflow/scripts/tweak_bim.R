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

print(paste("input_file:", input_file))
print(paste("chr_number:", chr_number))
print(paste("output_file:", output_file))

col_names <- c("chr", "id", "unknown", "pos", "ref", "alt")

f <- readr::read_tsv(input_file, col_names = col_names)

print("Original format:")
print(f)

f <- f %>% mutate(
  chr = chr_number,
  id = paste(chr, pos, ref, alt, sep = ":")
)

print("New format:")
print(f)

readr::write_tsv(output_file, col_names = F)
