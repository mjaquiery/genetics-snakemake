# Filter ids to only include ones with partner genetic data
install.packages("tidyverse")
library(tidyverse)
ids <- read.csv(snakemake$input$link) %>% as_tibble()

partner_ids <- read.table(snakemake$input$partner, header=T) %>%
  as_tibble() %>%
  mutate(id = str_extract(ID_1, "\\d+"))

ok_ids <- ids %>%
	rename(
		partner = .data[[snakemake$config$dirname_partner]],
		mother = .data[[snakemake$config$dirname_mother]],
		child = .data[[snakemake$config$dirname_child]]
	)
  filter(partner %in% partner_ids$id)

ok_ids$partner %>% paste(collapse = " ") %>% write(snakemake$output$partner)
ok_ids$mother %>% paste(collapse = " ") %>% write(snakemake$output$mother)
ok_ids$child %>% paste(collapse = " ") %>% write(snakemake$output$child)
