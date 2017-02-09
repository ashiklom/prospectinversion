arg <- commandArgs(trailingOnly = TRUE)
if (is.na(arg[1])) {
    cmd <- 'qsub'
} else {
    cmd <- arg[1]
}

library(prospectinversion)
specdb <- src_postgres('leaf_spectra')

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

results <- tbl(specdb, 'results') %>% collect()
if (nrow(results) > 0) {
    samples_sub <- anti_join(samples_all, results)
} else {
    samples_sub <- samples_all
}

samples_run <- samples_sub %>% distinct(samplecode, modelname)

#test <- runInversion(db = specdb, samplecode = 

for (i in seq_len(nrow(samples_run))) {
    if (cmd == 'bash') {
        if (i > 3) break
    }
    sys <- system2(cmd, c('submit_run.sh', 
                          shQuote(samples_run[[i, 'samplecode']]), 
                          shQuote(samples_run[[i, 'modelname']])))
    if (sys != 0) {
        stop('Error running command')
    }
}
