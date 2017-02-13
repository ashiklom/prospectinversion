library(prospectinversion)
source('dbConnect.R')

samples_base <- tbl(specdb, 'spectra_info') %>%
    filter(spectratype %in% c('reflectance', 'pseudo-absorbance')) %>%
    inner_join(tbl(specdb, 'samples')) %>%
    distinct(samplecode) %>%
    collect()

samples_p4 <- samples_base %>% mutate(modelname = 'PROSPECT 4')
samples_p5 <- samples_base %>% mutate(modelname = 'PROSPECT 5')
samples_p5b <- samples_base %>% mutate(modelname = 'PROSPECT 5B')

samples_all <- full_join(samples_p4, samples_p5) %>%
    full_join(samples_p5b)

results <- tbl(specdb, 'results') %>%
    distinct(samplecode, modelname) %>%
    collect()
if (nrow(results) > 0) {
    samples_sub <- anti_join(samples_all, results)
} else {
    samples_sub <- samples_all
}

samples_run <- samples_sub %>% 
    distinct(samplecode, modelname) %>%
    arrange(modelname)

summary_table <- samples_run %>%
    group_by(modelname) %>%
    summarize(N = n())
nruns <- sum(summary_table$N)
print(summary_table) 
message('Total runs to do: ', nruns)
