library(prospectinversion)
source('dbConnect.R')

arg <- commandArgs(trailingOnly = TRUE)
if (is.na(arg[1])) {
    runnum <- 1
} else {
    runnum <- as.numeric(arg[1])
}

samples_run <- readRDS('runs_table.rds')
nruns <- nrow(samples_run)
if (runnum > nruns) {
    stop('Given run number ', runnum, 
         ' but only ', nruns, 'available.')
}

samplecode <- samples_run[[runnum, 'samplecode']]
modelname <- samples_run[[runnum, 'modelname']]
n_results <- tbl(resultsdb, 'results') %>%
    filter_(paste0('samplecode == ', shQuote(samplecode))) %>%
    filter_(paste0('modelname == ', shQuote(modelname))) %>%
    count %>%
    collect %>%
    .[['n']]
if (n_results > 0) {
    stop('Run found in results table. Skipping')
}

message('About to start run number: ', runnum, '\n',
        'Samplecode: ', samplecode, '\n',
        'Modelname: ', modelname, '\n',
        'Sleeping for 5 seconds...')
Sys.sleep(5)

stopifnot(!is.na(samplecode), !is.na(modelname))

results <- runInversion(db = specdb, samplecode = samplecode, modelname = modelname)

outdir <- file.path('results', modelname)
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
        db_merge_into(db = resultsdb, table = 'results', values = .,
                      by = c('samplecode', 'parameter', 'modelname'),
                      id_colname = 'resultid')
}

