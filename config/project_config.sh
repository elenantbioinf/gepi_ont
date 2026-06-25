#!/usr/bin/env bash

#Project configuration file for the gepi_ont pipeline

#This file defines project-specific variables and settings that are used throughout the pipeline. 
#It should be sourced at the beginning of each script.

#Current version: 1.1 (2026-06-09)
#01_initial_qc
#02_filtering_and_qc
#03_bam_comparison
#04_coverage_gap
#05_mark_duplicates

################################################
############# PIPELINE LOCATION ################
################################################

#Config directory and pipeline/project root directory

CONFIG_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
PIPELINE_DIR="$(dirname "$CONFIG_DIR")"


################################################
########### USER-EDITABLE SETTINGS #############
################################################

#Directory where this pipeline execution will write all generated files.
#Local default: WORKDIR="${PIPELINE_DIR}" - write outputs to the pipeline directory.
#Cluster mode: WORKDIR="/path/to/cluster/workdir" - write outputs to a separate work directory.
WORKDIR="${PIPELINE_DIR}"

#Directory containing the input BAM files for the pipeline.
#Local default: RAW_BAM_DIR="${PIPELINE_DIR}/data/raw" - input BAM files are located in the raw data directory of the pipeline.
#Cluster mode: RAW_BAM_DIR="/comun/DATA/wgs_date" - input BAM files are located in a shared cluster directory.
RAW_BAM_DIR="${PIPELINE_DIR}/data/raw"

#Directory containing any reference files or resources needed for the pipeline.
#Local default: RESOURCES_DIR="${PIPELINE_DIR}/resources" - resources are located in the resources directory of the pipeline.
#Cluster mode: RESOURCES_DIR="/path/to/cluster/resources" - resources are located in a shared cluster directory.
RESOURCES_DIR="${PIPELINE_DIR}/resources"

#---------------Filtering parameters-------------

FILTER_MIN_MAPQ=20
FILTER_MIN_READ_LENGTH=1000
FILTER_EXCLUDE_FLAGS=2308 #4 + 256 + 2048 = 2308: unmapped, secondary and supplementary alignments

#---------------Coverage gap thresholds-------------
COVERAGE_GAP_THRESHOLDS=(0 5)

################################################
############## UNTOUCHABLE SETTINGS ############
################################################
#Yes, untouchable.


##################### WARNING ##################
#Everything below this line is part of the internal pipeline structure.
#These settings are automatically derived from the user-editable section above.
#Do not modify anything below unless you are intentionally changing the pipeline structure.
################################################


#Do not touch anything below this line without a very good reason.
#       |   |   |   |   |  
#       V   V   V   V   V


################################################
#################### PATHS #####################
################################################

#Scripts directory containing all pipeline scripts (organized by module)
SCRIPTS_DIR="${PIPELINE_DIR}/scripts"

#Directory containing conda environments for the pipeline (one environment per module)
CONDA_ENV_DIR="${PIPELINE_DIR}/envs"

#Directories for results, logs and processed data (derived from WORKDIR)
RESULTS_DIR="${WORKDIR}/results"

LOGS_DIR="${WORKDIR}/logs"

DATA_DIR="${WORKDIR}/data"

PROCESSED_DATA_DIR="${DATA_DIR}/processed"

################################################
############ MODULE 01: INITIAL QC #############
################################################

#Scripts
INITIAL_QC_SCRIPTS_DIR="${SCRIPTS_DIR}/01_initial_qc"

#Results and logs
INITIAL_QC_RESULTS_DIR="${RESULTS_DIR}/01_initial_qc"
INITIAL_QC_LOGS_DIR="${LOGS_DIR}/01_initial_qc"


#################################################
######### MODULE 02: FILTERING AND QC ###########
#################################################

#Scripts
FILTERING_AND_QC_SCRIPTS_DIR="${SCRIPTS_DIR}/02_filtering_and_qc"

#Filtering output
FILTERED_BAM_DIR="${PROCESSED_DATA_DIR}"

#Filtering logs
FILTERING_LOGS_DIR="${LOGS_DIR}/02_filtering_and_qc/filtering"

#Post filtering QC
POST_FILTERING_QC_RESULTS_DIR="${RESULTS_DIR}/02_post_filtering_qc"
POST_FILTERING_QC_LOGS_DIR="${LOGS_DIR}/02_filtering_and_qc/post_filtering_qc"


#################################################
########## MODULE 03: BAM COMPARISON ############
#################################################

#Scripts
BAM_COMPARISON_SCRIPTS_DIR="${SCRIPTS_DIR}/03_bam_comparison"

#Results
BAM_COMPARISON_RESULTS_DIR="${RESULTS_DIR}/03_bam_comparison"


#################################################
########### MODULE 04: COVERAGE GAP #############
#################################################

#Scripts
COVERAGE_GAP_SCRIPTS_DIR="${SCRIPTS_DIR}/04_coverage_gap"

#Results and logs
COVERAGE_GAP_RESULTS_DIR="${RESULTS_DIR}/04_coverage_gap"
COVERAGE_GAP_LOGS_DIR="${LOGS_DIR}/04_coverage_gap"


#################################################
########## MODULE 05: MARK DUPLICATES ###########
#################################################

#Scripts
MARK_DUPLICATES_SCRIPTS_DIR="${SCRIPTS_DIR}/05_mark_duplicates"

#Results and logs
MARK_DUPLICATES_RESULTS_DIR="${RESULTS_DIR}/05_mark_duplicates"
MARK_DUPLICATES_LOGS_DIR="${LOGS_DIR}/05_mark_duplicates"
