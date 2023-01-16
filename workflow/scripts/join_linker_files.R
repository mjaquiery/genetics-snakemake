# Join together two linker files because of data corruption redownloading saga
original <- commandArgs(T)[2]
new <- commandArgs(T)[3]
to <- commandArgs(T)[4]

print(paste("original:", original))
print(paste("new:", new))
print(paste("to:", to))

library('haven')
library('tidyverse')

o <- read.csv(original)
n <- read_sav(new)

out <- o %>% left_join(n, by="cidB2677", suffix=c('.x', ''))

write_csv(out, to)