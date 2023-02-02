# Filter ids to only include ones with data in all .fam files

library(readr)  # for read_tsv
library(tidyverse)

print("find_complete_ids:")
print(paste("snakemake@input:", snakemake@input[[1]]))
print(paste("snakemake@output:", snakemake@output[[1]]))

col_names <- c("FID", "IID", "Var1", "Var2", "Var3", "Var4")

files <- tibble()

for (f_path in snakemake@input[[1]]) {
  print(glue("Opening {f_path}"))
  files <- files %>%
    bind_rows(readr::read_tsv(f_path, col_names = col_names))
}

print(glue("Total rows in fam files: {nrow(files)}"))

files <- files %>%
  select(IID) %>%
  group_by(IID) %>%
  summarise(n_present = n())

print("CHR saturation:")
print(files %>% group_by(n_present) %>% summarise(n_people = n()))

ok_names <- files %>% select(IID) %>% unique()

print(glue("Writing {nrow(ok_names)} to {snakemake@output[[1]]}"))

write_tsv(ok_names, file = snakemake@output[[1]], col_names = F)
