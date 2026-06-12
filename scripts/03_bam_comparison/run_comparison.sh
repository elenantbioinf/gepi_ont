#!/usr/bin/env bash

#This script runs the QC comparison analysis for a given sample
#It calls the compare_qc.py script to compare flagstat, stats, mosdepth,
#and nanoplot results between the raw and filtered BAM files.

#Use: bash run_comparison.sh -s <sample_name>

set -euo pipefail

#Inizializate variables for avoiding errors with set -u
SAMPLE_NAME=""

#Define usage of the script
usage () {
    echo "scripts/03_bam_comparison/run_comparison.sh"
    echo ""
    echo "Usage: bash $0 -s <sample_name>"
    echo ""
    echo "Description:"
    echo "  Run QC comparison between initial and post-filtering results for one sample"
    echo ""
    echo "Options:"
    echo "  -s  Sample ID"
    echo "  -h  Display this help message and exit"
}

#Parse command-line options
while getopts ":s:h" opt; do
    case ${opt} in
        s ) SAMPLE_NAME="$OPTARG" ;;
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

#Check if options are provided
if [[ -z "$SAMPLE_NAME" ]]; then
    echo "[ERROR] Missing required arguments." >&2
    usage
    exit 1
fi

#Load project config
source "${MET_ONT_CONFIG:-config/project_config.sh}"

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