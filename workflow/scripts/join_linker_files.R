# Join together two linker files because of data corruption redownloading saga
original <- commandArgs(T)[1]
new <- commandArgs(T)[2]
to <- commandArgs(T)[3]

print(paste("original:", original))
print(paste("new:", new))
print(paste("to:", to))

library('haven')
library('tidyverse')

o <- read.csv(original)
n <- read_sav(new)

out <- o %>% left_join(n, by="cidB2677", suffix=c('.x', ''))

write.csv(out, to)