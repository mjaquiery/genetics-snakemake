library(tidyverse)
write(letters %>% str_replace_all('[aeiou]', '*'), snakemake@output)
