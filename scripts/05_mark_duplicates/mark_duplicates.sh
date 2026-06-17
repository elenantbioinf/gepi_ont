#!/usr/bin/env bash

# This script marks duplicates in aligned BAM files using Picard MarkDuplicates.

# Use: bash mark_duplicates.sh -i <input_bam>

set -euo pipefail

#Inizializate variables to avoid error with set -u
INPUT_BAM=""

#Define usage of the script
usage () {
    echo "scripts/05_mark_duplicates/mark_duplicates.sh"
    echo ""
    echo "Usage: bash $0 -i <input.bam>"
    echo ""
    echo "Description:"
    echo "  Mark duplicates in a BAM file using Picard"
    echo ""
    echo "Options:"
    echo "  -i  Input BAM file"
    echo "  -h  Display this help message and exit"
}

#Parse command-line options
while getopts ":i:h" opt; do
    case ${opt} in
        i ) INPUT_BAM="$OPTARG" ;;
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
if [[ -z "$INPUT_BAM" ]]; then
    echo "[ERROR] Missing required arguments." >&2
    usage
    exit 1
fi

#Load project config
source "${MET_ONT_CONFIG:-config/project_config.sh}"

#Chekc if input BAM exists
if [[ ! -f "${INPUT_BAM}" ]]; then
    echo "[ERROR] Input BAM not found:"
    echo "[ERROR] ${INPUT_BAM}"
    echo "[ERROR] Please, run the filtering of BAM raw before this step"
    exit 1
fi

#Sample name
SAMPLE="$(basename "$INPUT_BAM" .bam)"

#Define results
MARKDUP_DIR="${MARK_DUPLICATES_RESULTS_DIR}/${SAMPLE}"
MARKDUP_BAM="${MARKDUP_DIR}/${SAMPLE}_markdup.bam"
MARKDUP_METRICS="${MARKDUP_DIR}/${SAMPLE}_markdup_metrics.txt"

#Define logs
LOGS_DIR="${MARK_DUPLICATES_LOGS_DIR}/${SAMPLE}"
LOGS_FILE="${LOGS_DIR}/${SAMPLE}_markdup.log"


#Info messages
echo "###########################################"
echo "Running duplicate marking for sample: ${SAMPLE}"
echo "Input BAM: ${INPUT_BAM}"
echo "###########################################"

echo "Creating output directory for BAM files with duplicates marked if it doesn't exist..."
mkdir -p "${MARKDUP_DIR}"
mkdir -p "${LOGS_DIR}"

echo "Marking duplicates in $INPUT_BAM..."
picard MarkDuplicates \
    I="$INPUT_BAM" \
    O="$MARKDUP_BAM" \
    M="$MARKDUP_METRICS" \
    CREATE_INDEX=true \
    VALIDATION_STRINGENCY=LENIENT \
    > "${LOGS_FILE}" 2>&1

echo "###########################################"
echo "Duplicates marked successfully"
echo "Output saved to $MARKDUP_BAM"
echo "Metrics saved to $MARKDUP_METRICS"
echo "Index created: $MARKDUP_BAM.bai"
echo "Log saved to $LOGS_FILE"
echo "###########################################"

