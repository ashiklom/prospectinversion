specdb <- dplyr::src_sqlite('leaf_spectra.db')
resultsdb <- dplyr::src_sqlite('results.db')

DBI::dbGetQuery(specdb$con, 'PRAGMA foreign_keys = on;')
DBI::dbGetQuery(resultsdb$con, 'PRAGMA foreign_keys = on;')
