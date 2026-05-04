#!/usr/bin/env bash

# Initialization script for the project
# This script creates the initial directory structure and sets up the environment

set -euo pipefail

echo "Initializing project structure..."

#Main project directories

mkdir -p data/raw
mkdir -p data/processed
mkdir -p scripts
mkdir -p results
mkdir -p logs
mkdir -p config
mkdir -p envs
mkdir -p resources

#Resources directories
mkdir -p resources/ref_genome
mkdir -p resources/clair3_model
mkdir -p resources/containers
mkdir -p resources/vep_data
mkdir -p resources/R_libs

echo "Project structure created successfully"
