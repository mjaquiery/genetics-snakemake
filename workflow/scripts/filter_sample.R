# qctool won't produce a .sample file to go with its filtered .bgen files
# So it's on us to do it
#
library(readr)
library(tibble)
library(dplyr)
library(purrr)
library(tidyr)
library(stringr)

print("filter_sample:")
print(paste("snakemake@input$sample:", snakemake@input$sample))
print(paste("snakemake@input$include_ids:", snakemake@input$include_ids))
print(paste("snakemake@output[[1]]:", snakemake@output[[1]]))

input_file <- snakemake@input$sample
include_ids_file <- snakemake@input$include_ids
output_file <- snakemake@output[[1]]

n_header_lines <- 2

header <- readr::read_lines(input_file, n_max = n_header_lines)
col_names <- c(
  "ID_1",
  "ID_2",
  "missing",
  "heterozygosity",
  "father",
  "mother",
  "sex",
  "plink_pheno",
)

print("Header:")
print(header)

f <- readr::read_delim(
  input_file,
  delim = " ",
  skip = n_header_lines,
  col_names = col_names[[1]]
)

print("Loaded data:")
print(f)

ids <- readr::read_tsv(include_ids_file, col_names = c("ID"))
print("Loaded ids:")
print(ids)

f <- f %>% mutate(include = ID_2 %in% ids$ID)

print("Summary:")
f %>% group_by(include) %>% summarise(n = n())

f <- f %>% filter(include) %>% select(-include)

readr::write_lines(header, output_file)
readr::write_delim(f, output_file, delim = " ", append = T)

print("Wrote new .sample file")
