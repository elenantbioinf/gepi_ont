#!/usr/bin/env bash

#This is the runner of the pipeline.

#v.0.5 - Update 2026/06/17

#Run gepi_ont pipeline from module 01 to module 05 using a manifest file.
#Each module is executed in its corresponding Conda environment.

#These modules include:
# - 01_initial_qc
# - 02_filtering_and_qc
# - 03_bam_comparison
# - 04_coverage_gap
# - 05_mark_duplicates

#Manifest: sample_id<\t>bam_path

#Use: bash scripts/runner_pipeline_01_05.sh path/to/manifest.tsv path/to/config.sh

##################################################
################## INTRODUCTION ##################
##################################################

set -euo pipefail

#Check input arguments
if [[ "$#" -ne 2 ]]; then
    echo "[ERROR] Usage:"
    echo "[ERROR] bash scripts/runner_pipeline_01_05.sh path/to/manifest.tsv path/to/config.sh"
    echo "[ERROR] Please, include both the manifest file and the config file as arguments"
    exit 1
fi

#Input argument
MANIFEST="$1"
CONFIG="$2"

#Check if the manifest file exists
if [[ ! -f "$MANIFEST" ]]; then
    echo "[ERROR] Manifest file not found: $MANIFEST"
    exit 1
fi

#Check if the config file exists
if [[ ! -f "$CONFIG" ]]; then
    echo "[ERROR] Config file not found: $CONFIG"
    exit 1
fi

#Load project configuration
source "$CONFIG"

#Export config path for internal scripts
export GEPI_ONT_CONFIG="$CONFIG"

#Create execution log
PIPELINE_EXECUTION_LOGS_DIR="${LOGS_DIR}/pipeline_executions"

mkdir -p "$PIPELINE_EXECUTION_LOGS_DIR"

PIPELINE_EXECUTION_LOG="${PIPELINE_EXECUTION_LOGS_DIR}/execution_$(date +%Y%m%d_%H%M%S).log"

#Redirect all pipeline execution output to both terminal and execution log
exec > >(tee -a "$PIPELINE_EXECUTION_LOG") 2>&1

#Terminal colors
CYAN="\033[1;36m"
MAGENTA="\033[1;35m"
YELLOW="\033[0;33m"
RESET="\033[0m"

#Initial info messages
echo -e "${YELLOW}"
echo "============================================================================="
echo "============================================================================="
echo -e "${MAGENTA}"
echo "      MMMM   MMMM  EEEEEEE  TTTTTTTT        OOOOOOO  NNN    NN  TTTTTTTT"
echo "      MM MM MM MM  EE          TT           OO   OO  NN N   NN     TT   "
echo "      MM   M   MM  EEEEE       TT    =====  OO   OO  NN  N  NN     TT   "
echo "      MM       MM  EE          TT           OO   OO  NN   N NN     TT   "
echo "      MM       MM  EEEEEEE     TT           OOOOOOO  NN    NNN     TT   "
echo -e "${YELLOW}"
echo "A modular and reproducible bioinformatics pipeline for ONT long-read BAM data"
echo ""
echo "============================================================================="
echo "============================================================================="
echo -e "${CYAN}"
echo "[INFO] Manifest: ${MANIFEST}"
echo "[INFO] Config: ${CONFIG}"
echo "[INFO] Pipeline directory: ${PIPELINE_DIR}"
echo "[INFO] Working directory: ${WORKDIR}"
echo "[INFO] Results directory: ${RESULTS_DIR}"
echo "[INFO] Logs directory: ${LOGS_DIR}"
echo "[INFO] Pipeline execution log: ${PIPELINE_EXECUTION_LOG}"
echo "[INFO] Processed BAM directory: ${PROCESSED_DATA_DIR}"
echo "[INFO] Execution: $(date +%Y%m%d_%H%M%S)"
echo ""
echo -e "${RESET}"

##################################################
################ READ THE MANIFEST ###############
##################################################

# Read the manifest line by line, skip the header, and extract SAMPLE_ID and BAM_PATH
tail -n +2 "$MANIFEST" | while IFS=$'\t' read -r SAMPLE_ID BAM_PATH; do
    
    #Check if the line is empty
    if [[ -z "${SAMPLE_ID:-}" ]]; then
        continue
    fi

    #Info messages
    echo ""
    echo "============================================================================="
    echo "                             START PIPELINE"
    echo "============================================================================="
    echo "[INFO] Processing sample: ${SAMPLE_ID}"
    echo "============================================================================="
    echo ""

    #Check if input BAM of $SAMPLE_ID exists
    if [[ ! -f "$BAM_PATH" ]]; then
        echo "[ERROR] Input BAM not found for ${SAMPLE_ID}:"
        echo "[ERROR] ${BAM_PATH}"
        exit 1
    fi

    #Check that $SAMPLE_ID and BAM name matches
    #This is for avoid errors like sample_id = paciente01 and bam_path = muestra1.bam
    BAM_BASENAME="$(basename "$BAM_PATH" .bam)"

    if [[ "$SAMPLE_ID" != "$BAM_BASENAME" ]]; then
        echo "[ERROR] sample_id does not match BAM basename"
        echo "[ERROR] sample_id: ${SAMPLE_ID}"
        echo "[ERROR] BAM basename: ${BAM_BASENAME}"
        echo "[ERROR] Please, check and match sample_id with the BAM filename without .bam"
        exit 1
    fi

    ##################################################
    ############### START THE ANALYSIS ###############
    ##################################################

    #=============MODULE 01: QC RAW FILES=============
    echo ""
    echo "-----------------------------------------------------------------------------"
    echo "[MODULE 01] INITIAL QUALITY CONTROL FOR ${SAMPLE_ID}"
    echo "-----------------------------------------------------------------------------"
    echo ""

    #Initial QC
    conda run -n gepi_ont_qc \
        bash "${INITIAL_QC_SCRIPTS_DIR}/run_quality_control.sh" -i "$BAM_PATH" -m initial

    #===============MODULE 02: FILTERING AND QC===============
    echo ""
    echo "-----------------------------------------------------------------------------"
    echo "[MODULE 02] FILTERING AND QC FOR ${SAMPLE_ID}"
    echo "-----------------------------------------------------------------------------"
    echo ""

    #Filtering step
    conda run -n bam_processing \
        bash "${FILTERING_AND_QC_SCRIPTS_DIR}/filter_bam.sh" -i "$BAM_PATH"

    #Check if filtered BAM and index exists
    FILTERED_BAM="${FILTERED_BAM_DIR}/${SAMPLE_ID}/${SAMPLE_ID}_filtered.bam"

    if [[ ! -f "$FILTERED_BAM" ]]; then
        echo "[ERROR] Filtered BAM was not created:"
        echo "[ERROR] ${FILTERED_BAM}"
        exit 1
    fi

    if [[ ! -f "${FILTERED_BAM}.bai" ]]; then
        echo "[ERROR] Filtered BAM index was not created:"
        echo "[ERROR] ${FILTERED_BAM}.bai"
        exit 1
    fi

    #Post-filtering QC step
    conda run -n gepi_ont_qc \
        bash "${INITIAL_QC_SCRIPTS_DIR}/run_quality_control.sh" -i "$FILTERED_BAM" -m post_filtering

    #===============MODULE 03: BAM COMPARISON ===============
    echo ""
    echo "-----------------------------------------------------------------------------"
    echo "[MODULE 03] COMPARISON OF QC BEFORE AND AFTER FILTERING FOR ${SAMPLE_ID}"
    echo "-----------------------------------------------------------------------------"
    echo ""

    conda run -n gepi_ont_qc \
        bash "${BAM_COMPARISON_SCRIPTS_DIR}/run_comparison.sh" -s "$SAMPLE_ID"
    
    #===============MODULE 04: COVERAGE GAP===============
    echo ""
    echo "-----------------------------------------------------------------------------"
    echo "[MODULE 04] COVERAGE GAP ANALYSIS FOR ${SAMPLE_ID}"
    echo "-----------------------------------------------------------------------------"
    echo ""

    conda run -n coverage_gap \
        bash "${COVERAGE_GAP_SCRIPTS_DIR}/run_coverage_gap.sh" -s "$SAMPLE_ID"
    
    #===============MODULE 05: MARK DUPLICATES===============
    echo ""
    echo "-----------------------------------------------------------------------------"
    echo "[MODULE 05] MARK DUPLICATES FOR ${SAMPLE_ID}"
    echo "-----------------------------------------------------------------------------"
    echo ""

    conda run -n mark_duplicates \
        bash "${MARK_DUPLICATES_SCRIPTS_DIR}/mark_duplicates.sh" -i "$FILTERED_BAM"

    #Check if markdup BAM and index exists
    FILTERED_SAMPLE="$(basename "$FILTERED_BAM" .bam)"
    MARKDUP_DIR="${MARK_DUPLICATES_RESULTS_DIR}/${FILTERED_SAMPLE}"
    MARKDUP_BAM="${MARKDUP_DIR}/${FILTERED_SAMPLE}_markdup.bam"
    MARKDUP_BAI="${MARKDUP_DIR}/${FILTERED_SAMPLE}_markdup.bai"
    MARKDUP_METRICS="${MARKDUP_DIR}/${FILTERED_SAMPLE}_markdup_metrics.txt"

    if [[ ! -f "$MARKDUP_BAM" ]]; then
        echo "[ERROR] MarkDuplicates BAM was not created:"
        echo "[ERROR] ${MARKDUP_BAM}"
        exit 1
    fi

    if [[ ! -f "$MARKDUP_BAI" ]]; then
        echo "[ERROR] MarkDuplicates BAM index was not created:"
        echo "[ERROR] ${MARKDUP_BAI}"
        exit 1
    fi    

    if [[ ! -f "$MARKDUP_METRICS" ]]; then
        echo "[ERROR] MarkDuplicates metrics file was not created:"
        echo "[ERROR] ${MARKDUP_METRICS}"
        exit 1
    fi

done

#Final messages
echo ""
echo "============================================================================="
echo "                             PIPELINE FINISHED"
echo "============================================================================="
echo ""
echo "[INFO] Modules 01 to 05 completed for all samples in:"
echo "[INFO] ${MANIFEST}"
echo ""