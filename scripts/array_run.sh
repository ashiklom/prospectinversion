#!/bin/bash
#$ -q "geo*"
#$ -pe omp 5
#$ -l h_rt=01:00:00
#$ -j y
#$ -o logs/
#$ -t 1-14000

Rscript submit_run.R $SGE_TASK_ID
