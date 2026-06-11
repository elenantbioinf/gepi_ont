#!/usr/bin/env bash

# This script runs mosdepth on BAM files

#It can be executed directly:
#   bash mosdepth.sh -i <input.bam> -p <output_prefix>

#Or it can be called from run_quality_control.sh.

set -euo pipefail

#Inizializate variables for avoiding errors with set -u
INPUT_BAM=""
PREFIX=""

#Define usage of the script
usage () {
    echo "scripts/01_initial_qc/mosdepth.sh"
    echo ""
    echo "Usage: bash $0 -i <input.bam> -p <output_prefix>"
    echo ""
    echo "Description:"
    echo "  Run mosdepth on an input BAM file and save coverage outputs using the provided prefix."
    echo ""
    echo "Options:"
    echo "  -i  Input BAM file"
    echo "  -p  Output prefix for mosdepth results"
    echo "  -h  Display this help message and exit"
}

#Parse command-line options
while getopts ":i:p:h" opt; do
    case ${opt} in
        i ) INPUT_BAM="$OPTARG" ;;
        p ) PREFIX="$OPTARG" ;;
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
if [[ -z "$INPUT_BAM" || -z "$PREFIX" ]]; then
    echo "[ERROR] Missing required arguments." >&2
    usage
    exit 1
fi

#Load project config
source "${MET_ONT_CONFIG:-config/project_config.sh}"

SAMPLE="$(basename "$INPUT_BAM" .bam)"

QC_LOGS_DIR="${QC_LOGS_DIR:-$INITIAL_QC_LOGS_DIR}"

LOG_DIR="${QC_LOGS_DIR}/${SAMPLE}/mosdepth"
LOG="${LOG_DIR}/$(basename "$PREFIX")_mosdepth.log"

echo "Creating output directory if it doesn't exist..."
mkdir -p "$(dirname "$PREFIX")"
mkdir -p "$LOG_DIR"

echo "Running mosdepth on $INPUT_BAM..."
mosdepth "$PREFIX" "$INPUT_BAM" 2> "$LOG"

echo "Mosdepth coverage analysis done."
echo "Output prefix: $PREFIX."
echo "Log: $LOG."