#!/usr/bin/env bash

#This is the runner of the pipeline.

#v.0.2 - Update 2026/06/09

#Run met_ont pipeline from module 01 to module 04 using a manifest file. 

#These modules include:
# - 01_initial_qc
# - 02_filtering_and_qc
# - 03_bam_comparison
# - 04_coverage_gap

#Manifest: sample_id<\t>bam_path

#Use: bash scripts/runner_pipeline_01_04.sh path/to/manifest.tsv path/to/config

##################################################
################## INTRODUCTION ##################
##################################################

set -euo pipefail

#Check input arguments
if [[ "$#" -ne 2 ]]; then
    echo "[ERROR] Usage:"
    echo "[ERROR] bash scripts/runner_pipeline_01_04.sh path/to/manifest.tsv path/to/config.sh"
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
export MET_ONT_CONFIG="$CONFIG"

#Initial info messages
echo ""
echo "============================================================================="
echo "============================================================================="
echo ""
echo "      MMMM   MMMM  EEEEEEE  TTTTTTTT        OOOOOOO  NNN    NN  TTTTTTTT"
echo "      MM MM MM MM  EE          TT           OO   OO  NN N   NN     TT   "
echo "      MM   M   MM  EEEEE       TT    =====  OO   OO  NN  N  NN     TT   "
echo "      MM       MM  EE          TT           OO   OO  NN   N NN     TT   "
echo "      MM       MM  EEEEEEE     TT           OOOOOOO  NN    NNN     TT   "
echo ""
echo "A modular and reproducible bioinformatics pipeline for ONT long-read BAM data"
echo ""
echo "============================================================================="
echo "============================================================================="
echo ""
echo "[INFO] Manifest: ${MANIFEST}"
echo "[INFO] Config: ${CONFIG}"
echo "[INFO] Pipeline directory: ${PIPELINE_DIR}"
echo "[INFO] Working directory: ${WORKDIR}"
echo "[INFO] Results directory: ${RESULTS_DIR}"
echo "[INFO] Logs directory: ${LOGS_DIR}"
echo "[INFO] Processed BAM directory: ${PROCESSED_DATA_DIR}"
echo ""


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
    #This is for evitate errors like sample_id = paciente01 and bam_path = muestra1.bam
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

    #Run the runner of QC
    bash "${INITIAL_QC_SCRIPTS_DIR}/run_quality_control.sh" "$BAM_PATH" initial

    #===============MODULE 02: FILTERING AND QC===============
    echo ""
    echo "-----------------------------------------------------------------------------"
    echo "[MODULE 02] FILTERING AND QC FOR ${SAMPLE_ID}"
    echo "-----------------------------------------------------------------------------"
    echo ""

    #Filtering step
    bash "${FILTERING_AND_QC_SCRIPTS_DIR}/filter_bam.sh" "$BAM_PATH"

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
    bash "${INITIAL_QC_SCRIPTS_DIR}/run_quality_control.sh" "$FILTERED_BAM" post_filtering

    #===============MODULE 03: BAM COMPARISON ===============
    echo ""
    echo "-----------------------------------------------------------------------------"
    echo "[MODULE 03] COMPARISON OF QC BEFORE AND AFTER FILTERING FOR ${SAMPLE_ID}"
    echo "-----------------------------------------------------------------------------"
    echo ""

    bash "${BAM_COMPARISON_SCRIPTS_DIR}/run_comparison.sh" "$SAMPLE_ID"
    
    #===============MODULE 04: COVERAGE GAP===============
    echo ""
    echo "-----------------------------------------------------------------------------"
    echo "[MODULE 04] COVERAGE GAP ANALYSIS FOR ${SAMPLE_ID}"
    echo "-----------------------------------------------------------------------------"
    echo ""

    bash "${COVERAGE_GAP_SCRIPTS_DIR}/run_coverage_gap.sh" "$SAMPLE_ID"
    
done

#Final messages
echo ""
echo "============================================================================="
echo "                             PIPELINE FINISHED"
echo "============================================================================="
echo ""
echo "[INFO] Modules 01 to 04 completed for all samples in:"
echo "[INFO] ${MANIFEST}"
echo ""