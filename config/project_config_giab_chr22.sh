#!/usr/bin/env bash

#Project configuration file for the Gepi-ONT pipeline validation using GIAB data.

#This file defines project-specific variables and settings that are used throughout the pipeline. 
#It should be sourced at the beginning of each script.

#Current version: 2026-08-11
#01_initial_qc
#02_filtering_and_qc
#03_bam_comparison
#04_coverage_gap
#05_mark_duplicates
#06_variant_calling
#07_variant_phasing

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
WORKDIR="${HOME}/gepi_ont_giab_validation"

#Directory containing the input BAM files for the pipeline.
#Local default: RAW_BAM_DIR="${PIPELINE_DIR}/data/raw" - input BAM files are located in the raw data directory of the pipeline.
#Cluster mode: RAW_BAM_DIR="/comun/DATA/wgs_date" - input BAM files are located in a shared cluster directory.
RAW_BAM_DIR="/DATA/ont_open_data_downloads/giab_chr22/merged"

#Directory containing any reference files or resources needed for the pipeline.
#Local default: RESOURCES_DIR="${PIPELINE_DIR}/resources" - resources are located in the resources directory of the pipeline.
#Cluster mode: RESOURCES_DIR="/path/to/cluster/resources" - resources are located in a shared cluster directory.
RESOURCES_DIR="${PIPELINE_DIR}/resources"

#Exact reference used to align the GIAB data
REFERENCE_GENOME="/DATA/ont_open_data_downloads/giab_reference/GCA_000001405.15_GRCh38_no_alt_analysis_set.fasta"

#------------Module execution switches-----------
#Set each variable to true to run the module, or false to skip it.

RUN_MODULE_01_INITIAL_QC=false
RUN_MODULE_02_FILTERING_AND_QC=false
RUN_MODULE_03_BAM_COMPARISON=false
RUN_MODULE_04_COVERAGE_GAP=false
RUN_MODULE_05_MARK_DUPLICATES=false
RUN_MODULE_06_VARIANT_CALLING=true
RUN_MODULE_07_VARIANT_PHASING=true

#------------Variant-calling switches-----------

RUN_CLAIR3=true
RUN_DEEPVARIANT=true
RUN_VARIANT_FILTERING=true

#---------------Filtering parameters-------------

FILTER_MIN_MAPQ=20
FILTER_MIN_READ_LENGTH=1000
FILTER_EXCLUDE_FLAGS=2308 #4 + 256 + 2048 = 2308: unmapped, secondary and supplementary alignments

#-------------Coverage gap thresholds------------
COVERAGE_GAP_THRESHOLDS=(0 5)

#----------------Clair3 parameters---------------

#Clair3 model matching the ONT chemistry and basecalling model
CLAIR3_MODEL="${RESOURCES_DIR}/clair3_model/r1041_e82_400bps_hac_v500"

#Maximum number of threads
CLAIR3_THREADS=8

#Sequencing platform: ont, hifi or ilmn
CLAIR3_PLATFORM="ont"

##Contig or region to analyze; leave empty to analyze all supported contigs.
#In this case, the region to analyze is chr22
CLAIR3_CONTIG="chr22"

#----------------Deepvariant parameters---------------
#Apptainer image containing DeepVariant
DEEPVARIANT_CONTAINER="${RESOURCES_DIR}/containers/deepvariant_1.10.0.sif"

#DeepVariant model
DEEPVARIANT_MODEL_TYPE="ONT_R104"

#Threads for the deepvariant analysis
DEEPVARIANT_THREADS=1

#Deepvariant region to analyse;
#leave empty to analyze all supported contigs, or specify a region using "chr22"
#In this configuration, the region to analyze is chr22
DEEPVARIANT_REGIONS="chr22"

#Deepvariant output optiones: boolean values
DEEPVARIANT_OUTPUT_GVCF=false
DEEPVARIANT_VCF_STATS_REPORT=false

################################################
############## UNTOUCHABLE SETTINGS ############
################################################
#      |   |   |   |   |   |   |   |   |   |
#      V   V   V   V   V   V   V   V   V   V

#Yes, untouchable.


##################### WARNING ##################
#Everything below this line is part of the internal pipeline structure.
#These settings are automatically derived from the user-editable section above.
#Do not modify anything below unless you are intentionally changing the pipeline structure.
################################################


#Do not touch anything below this line without a very good reason.
#      |   |   |   |   |   |   |   |   |   |
#      V   V   V   V   V   V   V   V   V   V


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


#################################################
########## MODULE 06: VARIANT CALLING ###########
#################################################

#Scripts
VARIANT_CALLING_SCRIPTS_DIR="${SCRIPTS_DIR}/06_variant_calling"

#Base results and logs
VARIANT_CALLING_RESULTS_DIR="${RESULTS_DIR}/06_variant_calling"
VARIANT_CALLING_LOGS_DIR="${LOGS_DIR}/06_variant_calling"

#Clair3 results and logs
CLAIR3_RESULTS_DIR="${VARIANT_CALLING_RESULTS_DIR}/variant_calling/clair3"
CLAIR3_LOGS_DIR="${VARIANT_CALLING_LOGS_DIR}/clair3"

#DeepVariant results and logs
DEEPVARIANT_RESULTS_DIR="${VARIANT_CALLING_RESULTS_DIR}/variant_calling/deepvariant"
DEEPVARIANT_LOGS_DIR="${VARIANT_CALLING_LOGS_DIR}/deepvariant"

#PASS variant filtering results and logs
VARIANT_FILTERING_RESULTS_DIR="${VARIANT_CALLING_RESULTS_DIR}/variant_filtering"
VARIANT_FILTERING_LOGS_DIR="${VARIANT_CALLING_LOGS_DIR}/variant_filtering"


#################################################
########## MODULE 07: VARIANT PHASING ###########
#################################################

#Scripts
VARIANT_PHASING_SCRIPTS_DIR="${SCRIPTS_DIR}/07_variant_phasing"

#Base results and logs
VARIANT_PHASING_RESULTS_DIR="${RESULTS_DIR}/07_variant_phasing"
VARIANT_PHASING_LOGS_DIR="${LOGS_DIR}/07_variant_phasing"

#Phasing results and logs
PHASED_RESULTS_DIR="${VARIANT_PHASING_RESULTS_DIR}/variant_phasing"

#Haplotagging results and logs
HAPLOTAGGED_RESULTS_DIR="${VARIANT_PHASING_RESULTS_DIR}/haplotagging"