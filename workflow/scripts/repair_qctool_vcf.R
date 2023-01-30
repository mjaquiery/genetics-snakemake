# qctool for some unknown reason is outputting VCF files that are
# slightly scrambled
#
# CHROM fields are all NA
# ID fields have chromosome number appended after a ;
#
# We need normal VCF files, so this should produce them
#
library(readr)
library(tibble)
library(dplyr)
library(purrr)
library(tidyr)
library(stringr)

print("repair_qctool_vcf:")
print(paste("snakemake@input$vcf:", snakemake@input$vcf))
print(paste("snakemake@output$vcf:", snakemake@output$vcf))

input_file <- snakemake@input$vcf
output_file <- snakemake@output$vcf

input_file <- "G:/Documents/Programs/Python/genetics-snakemake/data/tmp_22_g0m_mini.vcf"

header <- readr::read_lines(input_file, n_max = 3)
col_names <- str_remove(header[3], "#") %>%
  str_split("\t")

f <- readr::read_delim(input_file, delim = "\t", skip = 3, col_names = col_names[[1]])

print("Loaded VCF data")

d <- f %>%
  select(-CHROM) %>%
  mutate(
    tmp = str_split(ID, ";"),
    CHROM = map_chr(tmp, ~ .[2]),
    CHROM = as.integer(CHROM),
    ID = map_chr(tmp, ~ .[1])
  ) %>%
  select(CHROM, everything(), -tmp)

print("Converted VCF data")

readr::write_lines(header, output_file)
readr::write_delim(d, output_file, delim = "\t", append = T)

print("Wrote new VCF file")
