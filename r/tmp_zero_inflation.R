#################################
"INVESTIGATING ZERO INFLATION"
################################

library(tidyverse)


# First check weights on linear model:

dummy <- tibble(
  
  id = c(rep("A", 4), rep("B", 2), rep("C", 4)),
  months_to_death = c(1, 2, 3, 4,
                      11, 13, # try 10 to check the weightedness
                      11, 12, 13, 14)
)

dummy %>% mutate(n_adm = 20 - months_to_death/0.7)

# (20 - 1/0.7)
# (20 - 2/0.7)
# (20 - 3/0.7)
# (20 - 14/0.7)

dummy2 <- tibble(
  
  id = c(rep("A", 4), rep("B", 2), rep("C", 4)),
  months_to_death = c(1, 2, 3, 4,
                      "M12", "M10", 
                      "M12", "M11", "M10", "M9"),
  month = c(paste0("M", 9:12), "M12", "M10", rep(NA, 4)),
  n_adm = c(10, 5, 2, 2, 1, 1, rep(0, 4)),
  freq = c(rep(1,6), rep(4,4)), # Must take into account the subtraction
  result = c(rep(1, 6), 5-2, 5-1, 5-2, 5-1)  # 5 is the background population
) %>% mutate(months_to_death = as.character(months_to_death)) 

dummy2 <- dummy2 %>% 
  mutate(month = ifelse(months_to_death %in% 1:12, month, months_to_death))

lookup <- dummy2 %>% filter(n_adm > 0 ) %>% count(month)

non_adm <- dummy2 %>% filter(n_adm == 0) %>%
  left_join(lookup, "month") %>% 
  mutate(n = freq - n)


# feed result to weights

dummy2 %>% uncount(result)

ggplot(data = dummy2, aes(months_to_death, n_adm))+
  geom_point()

ggplot(dummy2 %>% uncount(result), aes(n_adm))+
  geom_histogram()

# Zero inflated nb mixed model with frequency weighting.

install.packages("pscl")
library(pscl)
# large data sets.

dummy2 <- dummy2 %>% 
  mutate(months_to_death = as.factor(months_to_death)) %>% 
  mutate(n_adm = as.integer(n_adm))
  

m1 <- zeroinfl(n_adm ~ months_to_death | freq,
               data = dummy2, dist = "negbin")

# too small?
summary(m1)

zinb <- read.csv("https://stats.idre.ucla.edu/stat/data/fish.csv")
zinb <- within(zinb, {
  nofish <- factor(nofish)
  livebait <- factor(livebait)
  camper <- factor(camper)
})

m1 <- zeroinfl(count ~ nofish | nofish,
               data = zinb, dist = "negbin", EM = TRUE, weights = persons)
summary(m1)

# one <- 13 - as.numeric(dummy2$months_to_death[dummy2$months_to_death %in% 1:12])
# two <- paste0("M", one)
