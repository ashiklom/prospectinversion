#!/bin/bash -l
#$ -q "geo*"
#$ -pe omp 5
#$ -l h_rt=02:00:00
#$ -j y
#$ -o logs/
#$ -t 1-311

Rscript submit_run.R $SGE_TASK_ID
