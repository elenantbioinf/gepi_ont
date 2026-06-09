#!/usr/bin/env bash

#This script runs coverage gaps detection. 
#It uses mosdepth per-base BED.GZ file generating during post-filtering QC

#Use: bash scripts/04_coverage_gap/run_coverage_gap.sh <sample_id>

set -euo pipefail

#Check arguments
if [[ "$#" -ne 1 ]]; then
    echo "[ERROR] Missing arguments."
    echo "[ERROR] Usage: bash scripts/04_coverage_gap/run_coverage_gap.sh <sample_id>"
    exit 1
fi

#Load project config
source "${MET_ONT_CONFIG:-config/project_config.sh}"

#Input argument
SAMPLE_ID="$1"

#Filtered sample name
FILTERED_SAMPLE="${SAMPLE_ID}_filtered"

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
SAMPLE_LOGS_DIR="${COVERAGE_GAP_LOGS_DIR}/${SAMPLE_ID}"
mkdir -p "$SAMPLE_LOGS_DIR"

#Info messages
echo "###########################################"
echo "Running coverage gap analysis for sample: ${FILTERED_SAMPLE}"
echo "Input BED file: ${PER_BASE_BED}"
echo "Thresholds: ${COVERAGE_GAP_THRESHOLDS[*]}"
echo "###########################################"

#Define results dir for each sample
SAMPLE_RESULTS_DIR="${COVERAGE_GAP_RESULTS_DIR}/${SAMPLE_ID}"

#Run coverage gap detection for each threshold
for THRESHOLD in "${COVERAGE_GAP_THRESHOLDS[@]}"; do

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