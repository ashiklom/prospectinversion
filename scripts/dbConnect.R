specdb <- src_sqlite('~/dietzelab/curated-leafspec/leaf_spectra.db')
DBI::dbGetQuery(specdb$con, 'PRAGMA foreign_keys = on;')
