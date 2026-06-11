#!/usr/bin/env bash

# This script runs nanoplot on BAM files

#It can be executed directly:
#   bash nanoplot.sh -i <input.bam> -o <output_directory>

#Or it can be called from run_quality_control.sh.

set -euo pipefail

#Inizializate variables for avoiding errors with set -u
INPUT_BAM=""
OUTDIR=""

#Define usage of the script
usage () {
    echo "scripts/01_initial_qc/nanoplot.sh"
    echo ""
    echo "Usage: bash $0 -i <input.bam> -o <output_directory>"
    echo ""
    echo "Description:"
    echo "  Run NanoPlot on an input BAM file and save QC reports in the provided output directory."
    echo ""
    echo "Options:"
    echo "  -i  Input BAM file"
    echo "  -o  Output directory for NanoPlot results"
    echo "  -h  Display this help message and exit"
}

#Parse command-line options
while getopts ":i:o:h" opt; do
    case ${opt} in
        i ) INPUT_BAM="$OPTARG" ;;
        o ) OUTDIR="$OPTARG" ;;
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
if [[ -z "$INPUT_BAM" || -z "$OUTDIR" ]]; then
    echo "[ERROR] Missing required arguments." >&2
    usage
    exit 1
fi

#Load project config
source "${MET_ONT_CONFIG:-config/project_config.sh}"

SAMPLE="$(basename "$INPUT_BAM" .bam)"

QC_LOGS_DIR="${QC_LOGS_DIR:-$INITIAL_QC_LOGS_DIR}"

LOG_DIR="${QC_LOGS_DIR}/${SAMPLE}/nanoplot"
LOG="${LOG_DIR}/${SAMPLE}_nanoplot.log"

echo "Creating output directory if it doesn't exist..."
mkdir -p "$OUTDIR"
mkdir -p "$LOG_DIR"

echo "Running NanoPlot on $INPUT_BAM..."
NanoPlot --bam "$INPUT_BAM" -o "$OUTDIR" -p "$SAMPLE" 2> "$LOG"

echo "NanoPlot analysis done."
echo "Output directory: $OUTDIR."
echo "Log: $LOG."