#!/usr/bin/env bash

# This script runs samtools flagstat on BAM files

#It can be executed directly:
#   bash flagstat.sh <input.bam> <output.txt>

#Or it can be called from run_quality_control.sh.

set -euo pipefail

#Load project config
source "${MET_ONT_CONFIG:-config/project_config.sh}"

BAM="$1"
OUT="$2"

QC_LOGS_DIR="${QC_LOGS_DIR:-$INITIAL_QC_LOGS_DIR}"

SAMPLE="$(basename "$BAM" .bam)"

LOG_DIR="${QC_LOGS_DIR}/${SAMPLE}/samtools"
LOG="${LOG_DIR}/$(basename "$OUT" .txt).log"

echo "Creating output directory for flagstat results if it doesn't exist..."
mkdir -p "$(dirname "$OUT")"
mkdir -p "$LOG_DIR"

echo "Running samtools flagstat on $BAM..."
samtools flagstat "$BAM" > "$OUT" 2> "$LOG"

echo "SAMtools flagstat analysis done."
echo "Output: $OUT."
echo "Log: $LOG."