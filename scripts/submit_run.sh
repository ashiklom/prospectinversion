#!/bin/bash
#$ -q "geo*"
#$ -pe omp 5
#$ -l h_rt=04:00:00

Rscript submit_run.R "$1" "$2"
