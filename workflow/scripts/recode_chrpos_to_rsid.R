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

header_of_file <- readr::read_lines(input_file, n_max = 300)
header <- list()
for (x in header_of_file) {
  if (str_starts(x, '#'))
    header[length(header) + 1] <- x
  else
    break
}

col_names <- str_remove(header[length(header)], "#") %>%
  str_split("\t")

print("VCF header:")
print(header[1:(length(header) - 1)])
print(glue("Plus {length(col_names[[1]])} column names starting {paste(col_names[[1]][1:9], collapse = ', ')}"))


f <- readr::read_delim(
  input_file,
  delim = "\t",
  comment = "#",
  col_names = col_names[[1]],
  col_types = cols(.default = col_character())
)

print("VCF structure:")
print(f)

chr_whitelist <- unique(f$CHROM)

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

print("Converted VCF structure:")
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

readr::write_lines(header, output_file)
readr::write_delim(f, output_file, delim = "\t", append = T)

print("Wrote new VCF file")
