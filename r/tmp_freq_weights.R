#################################
"INVESTIGATING FREQUENCY WEIGHTS"
################################

library(tidyverse)
# library(survey)
library(broom)


set.seed(101)

N <- 30 # number of observations

# Aggregated data
aggregated <- tibble(x = 1:5) %>%
  mutate(y    = round(2 * x + 2 + rnorm(length(x))),
         freq = as.numeric(table(sample(1:5,
                                        N,
                                        replace = TRUE,
                                        prob = c(.1, .1, .6, .1, .1)))))
  )
aggregated

# individuals <- aggregated[rep(1:5, aggregated$freq), c("x", "y")]

individuals <- aggregated %>% uncount(freq)


ggplot(aggregated, aes(x, y=y, size=freq)) + geom_point() + theme_bw()


models <- list( 
  ind_lm  = lm(y ~ x, data=individuals),
  raw_agg = lm( y ~ x, data=aggregated),
  # ind_svy_glm = svyglm(y~x, design=svydesign(id=~1, data=individuals),
  #                      family=gaussian() ),
  ind_glm = glm(y ~ x, family=gaussian(), data=individuals),
  wei_lm  = lm(y ~ x, data=aggregated, weight=freq),
  wei_glm = glm(y ~ x, data=aggregated, family=gaussian(), weight=freq) #,
  # svy_glm = svyglm(y ~ x, design=svydesign(id=~1, weights=~freq, data=aggregated),
  #                  family=gaussian())
)


results <- map_df(names(models), function(n) cbind(model=n, tidy(models[[n]]))) %>%
  gather(stat, value, -model, -term) %>% 
  arrange(term)

results %>% filter(stat=="estimate") %>% 
  select(model, term, value) %>%
  spread(term, value)


# Standard Errors
results %>% filter(stat=="std.error") %>%
  select(model, term, value) %>%
  spread(term, value)

models$wei_lm$coefficients

models$wei_lm_fixed <- models$wei_lm
models$wei_lm_fixed$df.residual <- with(models$wei_lm_fixed, sum(weights) - length(coefficients))

results <- do.call("rbind", lapply( names(models), function(n) cbind(model=n, tidy(models[[n]])) )) %>%
  gather(stat, value, -model, -term)

broom::glance(models$wei_lm_fixed)

map_df(names(models), function(x) cbind(model=n, glance(models[n])))

glance(models$wei_lm_fixed)

glance(models[[names(models)[i]]])

models[["ind_lm"]]

imap(names(models), function(x) glance(models[[names(models)[i]]]))

imap(models, cat)

glance(models$wei_lm_fixed)
glance(models$wei_lm)
glance(models$ind_lm)
