# Take a VCF file with chr:pos identifiers and use
# chr:pos + variant info to recode from a mapper file
#
library(readr)
library(dplyr)
library(tidyr)
library(stringr)
library(glue)

print("recode_chrpos_to_rsid:")

input_file <- commandArgs(T)[2]
map_file <- commandArgs(T)[3]
output_file <- commandArgs(T)[4]

print(paste("input_file:", input_file))
print(paste("map_file:", map_file))
print(paste("output_file:", output_file))

map <- readr::read_delim(
  map_file,
  delim = "\t",
  comment = "#",
  col_names = c("CHROM", "POS", "ID", "REF", "ALT", "QUAL", "FILTER", "INFO")
) %>%
  mutate(chrpos = glue("{CHROM}:{POS}")) %>%
  select(chrpos, rsID = ID, REF, ALT)

print("Mapper structure:")
print(head(map))

header <- readr::read_lines(input_file, n_max = 3)
col_names <- str_remove(header[3], "#") %>%
  str_split("\t")

f <- readr::read_delim(input_file, delim = "\t", skip = 3, col_names = col_names[[1]])

print("VCF structure:")
print(head(f))

f <- f %>%
  left_join(
    map,
    by = c("ID" = "chrpos", "REF" = "REF", "ALT" = "ALT")
  )
  mutate(ID = rsID) %>%
  select(everything(), -rsID)

print("Converted VCF data")
print(head(f))

readr::write_lines(header, output_file)
readr::write_delim(f, output_file, delim = "\t", append = T)

print("Wrote new VCF file")