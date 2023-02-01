# Assign PRS from PRSice output and match with cid
#
library(tidyverse)

root <- "G:/Documents/Programs/Python/genetics-snakemake/data/tmp/"
link <- paste0(root, "linker_file.csv")
sources <- tribble(
  ~source, ~prsice, ~scores,
  "gi_1000g_g0p", "g0p/prs.prsice", "g0p/prs.all_score",
  "gi_1000g_g0m_g1", "g0m/prs.prsice", "g0m/prs.all_score",
)


# read in data
linkfile <- read_csv(link)

d_all <- sources %>%
  mutate(
    prsice = map(prsice, ~ read_tsv(paste0(root, .))),
    scores = map(scores, ~ read_delim(paste0(root, .), delim = " ")),
    scores = map(scores, ~ select(., IID, Pt_1))  # just want PRS @ P-value=1
  ) %>%
  mutate(
    scores = map2(scores, source, function(scores, src) {
      scores %>%
        # deduplicate ids
        mutate(IID = str_match(IID, "(.+)_\\1")[,2]) %>%
        # split off role marker
        separate(IID, c(src, "role"), -1)
    })
  )

d_prs <- d_all %>%
  mutate(
    scores = map2(source, scores, function(src, df) {
      link <- linkfile %>% select({src}, cidB2677) %>%
        mutate(across(everything(), as.character))
      left_join(df, link, by = c(src)) %>%
        filter(!is.na(cidB2677)) %>%
        rename(IID = {src})
    })
  )

prs_long <- bind_rows(d_prs$scores)
prs_wide <- pivot_wider(
  prs_long,
  id_cols = cidB2677,
  names_from = role,
  values_from = Pt_1
)
prs_wide_filtered <- prs_wide %>%
  filter(!is.na(M) & !is.na(`F`) & !is.na(A))
prs_long_filtered <- prs_long %>%
  filter(cidB2677 %in% prs_wide_filtered$cidB2677) %>%
  mutate(src = if_else(str_starts(IID, 'gi_'), 'g0p', 'g0m'))

write_tsv(prs_wide_filtered, paste0(root, "prs.tsv"))

# examine output
range(prs_long$Pt_1)

ggplot(prs_long, aes(x = Pt_1, fill = role)) +
  geom_histogram(bins = 100, position = 'identity') +
  facet_wrap(~role) +
  theme_light()

cor(prs_wide_filtered$M, prs_wide_filtered$A)
cor(prs_wide_filtered$M, prs_wide_filtered$B, use = "pairwise.complete.obs")
cor(prs_wide_filtered$M, prs_wide_filtered$`F`)
cor(prs_wide_filtered$`F`, prs_wide_filtered$A)
cor(prs_wide_filtered$`F`, prs_wide_filtered$B, use = "pairwise.complete.obs")

prs_long_filtered %>%
  group_by(src, role) %>%
  summarise(n = n())
