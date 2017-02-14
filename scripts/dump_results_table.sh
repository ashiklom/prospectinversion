#!/bin/bash
echo -e 'PRAGMA foreign_keys = on;\n.dump results' | sqlite3 ../../curated-leafspec/leaf_spectra.db > results.sql
