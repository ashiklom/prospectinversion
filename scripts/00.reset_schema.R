schema_file <- system.file('schema.sql', package = 'prospectinversion')
system2('sqlite'
system2('psql', c('-d', 'leaf_spectra', '-c', shQuote('DROP TABLE results')))
system2('psql', c('-d', 'leaf_spectra', '-f', schema_file))
