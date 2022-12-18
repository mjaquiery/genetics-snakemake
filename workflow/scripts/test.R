library(tidyverse)
print(snakemake)
write(letters %>% str_replace_all('[aeiou]', '*'), snakemake@output)
