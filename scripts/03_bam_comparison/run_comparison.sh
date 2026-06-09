#!/usr/bin/env bash

#This script runs the QC comparison analysis for a given sample
#It calls the compare_qc.py script to compare flagstat, stats, mosdepth,
#and nanoplot results between the raw and filtered BAM files.

#Use: bash run_comparison.sh <sample_name>

set -euo pipefail

#Check arguments
if [[ "$#" -ne 1 ]]; then
    echo "[ERROR] Usage: bash run_comparison.sh <sample_name>"
    exit 1
fi

#Load project config
source "${MET_ONT_CONFIG:-config/project_config.sh}"

#Input argument
SAMPLE_NAME="$1"

#Output directory for comparison results
OUTPUT_DIR="$BAM_COMPARISON_RESULTS_DIR/${SAMPLE_NAME}"

#Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

#Info messages
echo "###########################################"
echo "Running BAM comparison for sample: ${SAMPLE_NAME}"
echo "###########################################"

#Run the comparison Python script
python3 "${BAM_COMPARISON_SCRIPTS_DIR}/compare_qc.py" \
    "$SAMPLE_NAME" \
    "$RESULTS_DIR" \
    "$OUTPUT_DIR"

#Final message
echo "###########################################"
echo "BAM comparison completed for sample: ${SAMPLE_NAME}"
echo "Results directory: ${OUTPUT_DIR}"
echo "###########################################"