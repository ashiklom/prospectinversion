#' Get spectra for a given samplecode
#'
#' @inheritParams initModel
#' @param samplecode `samplecode` from `results` table
#' @param spectratypes (character) Spectra types to be included. If `NULL`, use all spectra types.
#' @export
getSpectra <- function(db, samplecode,
                       spectratypes = c('reflectance', 'pseudo-absorbance')) {
    spectra <- tbl(db, 'samples') %>%
        filter_(paste0("samplecode == ", shQuote(samplecode))) %>%
        inner_join(tbl(db, 'spectra_info'))
    if (!is.null(spectratypes)) {
        spectra <- filter_(spectra, ~spectratype %in% spectratypes)
    } else {
        spectratypes <- 'all'
    }

    spectra_count <- spectra %>% count %>% collect %>% .[['n']]
    if (spectra_count == 0) {
        warning('No spectra of type ', 
                paste(spectratypes, collapse = ', '),
                ' found for samplecode ', shQuote(samplecode), 
                '. Returning NULL')
        return(NULL)
    }
    spectra_types <- distinct_(spectra, ~spectratype) %>% collect %>% .[['spectratype']]
    if (length(spectra_types) > 1) {
        warning('Found multiple spectra types (', 
                paste(spectra_types, collapse = ', '),
                ') for samplecode ', shQuote(samplecode))
    }
    specdata <- spectra %>%
        select_(~spectraid) %>%
        left_join(tbl(db, 'spectra_data')) %>%
        select_(~-spectradataid) %>%
        collect %>%
        spread_(key_col = 'spectraid', value_col = 'spectravalue')
    attr(specdata, 'spectratype') <- spectra_types
    return(specdata)
}

samplecode <- "accp|92BHIS10BW1|1992"
