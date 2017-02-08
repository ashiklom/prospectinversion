#' Initialize results table for model
#' 
#' @param specdb `dplyr` `src` object pointing to spectra database
#' @param modelname Name of model with which to initialize table
#' @export
initModel <- function(specdb, modelname) {
    specsamples <- tbl(specdb, 'spectra_info') %>%
        inner_join(tbl(specdb, 'samples')) %>%
        filter_(~spectratype %in% c('reflectance', 'pseudo-absorbance')) %>%
        distinct_('samplecode') %>%
        collect()
    results_init <- specsamples %>%
        mutate_(.dots = list(modelname = ~modelname,
                             runstatus = ~'not started')) %>%
        db_merge_into(db = specdb, table = 'results', values = .,
                      by = c('samplecode', 'modelname'), id_colname = 'resultid')
    return(results_init)
}
