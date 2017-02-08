library(prospectinversion)
specdb <- src_postgres('leaf_spectra')

if (!interactive()) {
    arg <- commandArgs(trailingOnly = TRUE)
    samplecode <- arg[1]
    modelname <- arg[2]
} else {
    samplecode <- 'accp|92BHIS11SM1|1992'
    modelname <- 'PROSPECT 4'
}

stopifnot(!is.na(samplecode), !is.na(modelname))

message('Running with the following arguments:\n',
        'SampleCode: ', samplecode, '\n',
        'Model: ', modelname)

results <- runInversion(db = specdb, samplecode = samplecode, modelname = modelname)

outdir <- 'results'
dir.create(outdir, showWarnings = FALSE)
filename <- file.path(outdir, paste0(samplecode, '.rds'))
saveRDS(object = results, file = filename)

# Process results
if (is.null(results$results)) {
    warning('Run of sample ', shQuote(samplecode), ' failed.')
} else {
    message('Run of sample ', shQuote(samplecode), ' completed successfully!')
    list_summarize <- . %>%
        PEcAn.assim.batch::makeMCMCList() %>%
        window(start = results$burnin) %>%
        unlist %>%
        (function(.) list(mu = mean(.),
                          sigma = sd(.),
                          q025 = quantile(., 0.025), 
                          q500 = quantile(., 0.500),
                          q975 = quantile(., 0.975))) %>%
        (function(.) tibble(param_names = names(.), values = unlist(.)))
    results_neff <- results$n_eff_list %>% 
        list_summarize %>%
        mutate(param_names = paste0('neff.', param_names))
    results_deviance <- results$deviance_list %>% 
        list_summarize %>%
        mutate(param_names = paste0('deviance.', param_names))

    results_table <- tibble(param_names = names(results$results),
                            values = unlist(results$results)) %>%
        bind_rows(results_neff) %>%
        bind_rows(results_deviance) %>%
        separate(param_names, c('parameter', 'stat')) %>%
        mutate(stat = recode(stat, 
                             mu = 'parametermean', 
                             sigma = 'parametersd',
                             q25 = 'parameterq025',
                             q025 = 'parameterq025',
                             med = 'parameterq500',
                             q500 = 'parameterq500',
                             q975 = 'parameterq975',
                             .default = stat)) %>%
        spread(key = stat, value = values) %>%
        mutate(samplecode = samplecode, modelname = modelname) %>%
        db_merge_into(db = specdb, table = 'results', values = .,
                      by = c('samplecode', 'parameter', 'modelname'),
                      id_colname = 'resultid')
}
