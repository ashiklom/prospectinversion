#!/bin/bash
#$ -q "geo*"
#$ -pe omp 5
#$ -l h_rt=00:30:00
#$ -j y
#$ -o logs/

Rscript submit_run.R "$1" "$2"
