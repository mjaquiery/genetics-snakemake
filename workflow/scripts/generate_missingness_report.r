install.packages("tidyverse")
library(tidyverse)

# Look at missingness in genetic data (CHR_*)

d <- tibble()

for (f in snakemake$input) {
  d <- bind_rows(
    d,
    read.table(f, header = T) %>%
      as_tibble() %>%
      mutate(chr = i)
  )
}

d <- d %>% mutate(proportion_missing = round(F_MISS, 2))

d %>%
  group_by(chr, proportion_missing) %>%
  summarise(n = n()) %>%
  write.table(snakemake$output, sep="\t", header=T)