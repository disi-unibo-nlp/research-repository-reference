#!/bin/bash
#SBATCH --job-name=test_cluster
#SBATCH --mail-type=ALL
#SBATCH --mail-user=lorenzo.molfetta@unibo.it
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=31G
#SBATCH --partition=l40
#SBATCH --output=test_vllm.out
#SBATCH --chdir=/scratch.hpc/lorenzo.molfetta2/research-repository-reference
#SBATCH --gres=gpu:1

test_venv/bin/python3.11 src/evaluation/inference_with_vllm.py