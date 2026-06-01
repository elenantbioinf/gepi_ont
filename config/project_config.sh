#!/usr/bin/env bash

#Project configuration file for the met_ont pipeline

#This file defines project-specific variables and settings that are used throughout the pipeline. 
#It should be sourced at the beginning of each script.

#Current version: 1.0 (2026-06-01)
#01_initial_qc
#02_filtering_and_qc
#03_bam_comparison

################################################
################ PROJECT PATHS #################
################################################

CONFIG_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
PROJECT_DIR="$(dirname "$CONFIG_DIR")"

SCRIPTS_DIR="${PROJECT_DIR}/scripts"

RESULTS_DIR="${PROJECT_DIR}/results"
LOGS_DIR="${PROJECT_DIR}/logs"

DATA_DIR="${PROJECT_DIR}/data"
RAW_DATA_DIR="${DATA_DIR}/raw"
PROCESSED_DATA_DIR="${DATA_DIR}/processed"

RESOURCES_DIR="${PROJECT_DIR}/resources"

CONDA_ENV_DIR="${PROJECT_DIR}/envs"


################################################
############ MODULE 01: INITIAL QC #############
################################################

INITIAL_QC_SCRIPTS_DIR="${SCRIPTS_DIR}/01_initial_qc"

INITIAL_QC_RESULTS_DIR="${RESULTS_DIR}/01_initial_qc"
INITIAL_QC_LOGS_DIR="${LOGS_DIR}/01_initial_qc"

#################################################
######### MODULE 02: FILTERING AND QC ###########
#################################################

#----------------------Paths---------------------
#Scripts
FILTERING_AND_QC_SCRIPTS_DIR="${SCRIPTS_DIR}/02_filtering_and_qc"

#Filtering output
FILTERED_BAM_DIR="${PROCESSED_DATA_DIR}"

#Filtering logs
FILTERING_LOGS_DIR="${LOGS_DIR}/02_filtering_and_qc/filtering"

#Post filtering QC
POST_FILTERING_QC_RESULTS_DIR="${RESULTS_DIR}/02_post_filtering_qc"
POST_FILTERING_QC_LOGS_DIR="${LOGS_DIR}/02_filtering_and_qc/post_filtering_qc"

#---------------Filtering parameters-------------
FILTER_MIN_MAPQ=20
FILTER_MIN_READ_LENGTH=1000
FILTER_EXCLUDE_FLAGS=2308 #4 + 256 + 2048 = 2308: unmapped, secondary and supplementary alignments

#################################################
########## MODULE 03: BAM COMPARISON ############
#################################################

#----------------------Paths---------------------
#Scripts
BAM_COMPARISON_SCRIPTS_DIR="${SCRIPTS_DIR}/03_bam_comparison"

#Results
BAM_COMPARISON_RESULTS_DIR="${RESULTS_DIR}/03_bam_comparison"

