#!/usr/bin/env bash

#This script runs coverage gaps detection. 
#It uses mosdepth per-base BED.GZ file generating during post-filtering QC

#Use: bash scripts/04_coverage_gap/run_coverage_gap.sh -s <sample_id> [-t <threshold>]

set -euo pipefail

#Inizializate variables for avoiding errors with set -u
SAMPLE_NAME=""
SELECTED_THRESHOLD=""

#Define usage of the script
usage () {
    echo "scripts/04_coverage_gap/run_coverage_gap.sh"
    echo ""
    echo "Usage: bash $0 -s <sample_name> [-t <threshold>]"
    echo ""
    echo "Description:"
    echo "  Run coverage gap detection using mosdepth per-base BED.GZ from post-filtering QC"
    echo ""
    echo "Options:"
    echo "  -s  Sample ID"
    echo "  -t  Coverage threshold to run. If not provided, thresholds from project_config.sh are used"
    echo "  -h  Display this help message and exit"
}

#Parse command-line options
while getopts ":s:t:h" opt; do
    case ${opt} in
        s ) SAMPLE_NAME="$OPTARG" ;;
        t ) SELECTED_THRESHOLD="$OPTARG" ;;
        h ) usage
            exit 0 ;;
        \? )
            echo "[ERROR] Invalid option: -$OPTARG" >&2
            usage
            exit 1
            ;;
        : )
            echo "[ERROR] Option -$OPTARG requires an argument." >&2
            usage
            exit 1
            ;;
    esac
done

#Check if required options are provided
#Only required SAMPLE_NAME, if SELECTED_THRESHOLD is not provided, the script will use the
#thresholds from the configfile
if [[ -z "$SAMPLE_NAME" ]]; then
    echo "[ERROR] Missing required arguments." >&2
    usage
    exit 1
fi

#Load project config
source "${GEPI_ONT_CONFIG:-config/project_config.sh}"

#Define thresholds to run
if [[ -n "$SELECTED_THRESHOLD" ]]; then
    THRESHOLDS_TO_RUN=("$SELECTED_THRESHOLD")
else
    THRESHOLDS_TO_RUN=("${COVERAGE_GAP_THRESHOLDS[@]}")
fi

#Filtered sample name
FILTERED_SAMPLE="${SAMPLE_NAME}_filtered"

#Input mosdepth per-base.bed.gz from post-filtering QC
PER_BASE_BED="${POST_FILTERING_QC_RESULTS_DIR}/${FILTERED_SAMPLE}/mosdepth/${FILTERED_SAMPLE}.per-base.bed.gz"

#Check if per-base.bed.gz exists
if [[ ! -f "${PER_BASE_BED}" ]]; then
    echo "[ERROR] Mosdepth per-base file not found:"
    echo "[ERROR] ${PER_BASE_BED}"
    echo "[ERROR] Run post-filtering QC before coverage gap detection"
    exit 1
fi

#Logs directory
SAMPLE_LOGS_DIR="${COVERAGE_GAP_LOGS_DIR}/${SAMPLE_NAME}"
mkdir -p "$SAMPLE_LOGS_DIR"

#Info messages
echo "###########################################"
echo "Running coverage gap analysis for sample: ${FILTERED_SAMPLE}"
echo "Input BED file: ${PER_BASE_BED}"
echo "Thresholds: ${THRESHOLDS_TO_RUN[*]}"
echo "###########################################"

#Define results dir for each sample
SAMPLE_RESULTS_DIR="${COVERAGE_GAP_RESULTS_DIR}/${SAMPLE_NAME}"

#Run coverage gap detection for each threshold
for THRESHOLD in "${THRESHOLDS_TO_RUN[@]}"; do

    #Define threshold dir for each threshold
    THRESHOLD_DIR="${SAMPLE_RESULTS_DIR}/threshold_${THRESHOLD}"

    #Create output directory
    mkdir -p "${THRESHOLD_DIR}"

    #Define output files
    GAP_TSV="${THRESHOLD_DIR}/${FILTERED_SAMPLE}_gap${THRESHOLD}.tsv"
    SUMMARY_TSV="${THRESHOLD_DIR}/${FILTERED_SAMPLE}_gap${THRESHOLD}_summary.tsv"

    #Define logs files
    DETECT_COVERAGE_GAP_LOG="${SAMPLE_LOGS_DIR}/${FILTERED_SAMPLE}_gap${THRESHOLD}_detect.log"
    SUMMARY_COVERAGE_GAP_LOG="${SAMPLE_LOGS_DIR}/${FILTERED_SAMPLE}_gap${THRESHOLD}_summary.log"

    echo "------------------------------------------"
    echo "[INFO] Running coverage gap detection"
    echo "[INFO] Threshold: ${THRESHOLD}"
    echo "[INFO] Sample: ${FILTERED_SAMPLE}"

    python3 "${COVERAGE_GAP_SCRIPTS_DIR}/detect_coverage_gaps.py" \
        "${PER_BASE_BED}" \
        "${GAP_TSV}" \
        "${FILTERED_SAMPLE}" \
        "${THRESHOLD}" \
        2>&1 | tee "${DETECT_COVERAGE_GAP_LOG}"
    
    echo "[INFO] Coverage gap detection done."

    echo "------------------------------------------"
    echo "[INFO] Running coverage gap summary"
    echo "[INFO] Threshold: ${THRESHOLD}"
    echo "[INFO] Sample: ${FILTERED_SAMPLE}"

    python3 "${COVERAGE_GAP_SCRIPTS_DIR}/summarize_coverage_gaps.py" \
        "${GAP_TSV}" \
        "${SUMMARY_TSV}" \
        2>&1 | tee "${SUMMARY_COVERAGE_GAP_LOG}"

    echo "[INFO] Coverage gap summary done."

done

#Final message
echo "###########################################"
echo "Coverage gap analysis completed for sample: ${FILTERED_SAMPLE}"
echo "Results directory: ${SAMPLE_RESULTS_DIR}"
echo "Logs directory: ${SAMPLE_LOGS_DIR}"
echo "###########################################"