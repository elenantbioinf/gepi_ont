#!/usr/bin/env bash

# This script runs samtools flagstat on BAM files

#It can be executed directly:
#   bash flagstat.sh -i <input.bam> -o <output.txt>

#Or it can be called from run_quality_control.sh.

set -euo pipefail

#Inizializate variables for avoiding errors with set -u
INPUT_BAM=""
OUTPUT_METRICS=""

#Define usage of the script
usage () {
    echo "scripts/01_initial_qc/flagstat.sh"
    echo ""
    echo "Usage: bash $0 -i <input.bam> -o <output.txt>"
    echo ""
    echo "Description:"
    echo "  Run samtools flagstat on an input BAM file and save the output statistics."
    echo ""
    echo "Options:"
    echo "  -i  Input BAM file"
    echo "  -o  Output TXT file for samtools flagstat metrics"
    echo "  -h  Display this help message and exit"
}

#Parse command-line options
while getopts ":i:o:h" opt; do
    case ${opt} in
        i ) INPUT_BAM="$OPTARG" ;;
        o ) OUTPUT_METRICS="$OPTARG" ;;
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
if [[ -z "$INPUT_BAM" || -z "$OUTPUT_METRICS" ]]; then
    echo "[ERROR] Missing required arguments." >&2
    usage
    exit 1
fi

#Load project config
source "${MET_ONT_CONFIG:-config/project_config.sh}"

QC_LOGS_DIR="${QC_LOGS_DIR:-$INITIAL_QC_LOGS_DIR}"

SAMPLE="$(basename "$INPUT_BAM" .bam)"

LOG_DIR="${QC_LOGS_DIR}/${SAMPLE}/samtools"
LOG="${LOG_DIR}/$(basename "$OUTPUT_METRICS" .txt).log"

echo "Creating output directory for flagstat results if it doesn't exist..."
mkdir -p "$(dirname "$OUTPUT_METRICS")"
mkdir -p "$LOG_DIR"

echo "Running samtools flagstat on $INPUT_BAM..."
samtools flagstat "$INPUT_BAM" > "$OUTPUT_METRICS" 2> "$LOG"

echo "SAMtools flagstat analysis done."
echo "Output: $OUTPUT_METRICS."
echo "Log: $LOG."