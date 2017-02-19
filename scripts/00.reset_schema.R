schema_file <- system.file('schema.sql', package = 'prospectinversion')
results_file <- 'results.db'
file.remove(results_file)
system2('sqlite3', 'results.db', stdin = schema_file)
