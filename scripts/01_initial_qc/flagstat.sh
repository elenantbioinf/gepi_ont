#!/usr/bin/env bash

# This script runs samtools flagstat on BAM files

#It can be executed directly:
#   bash flagstat.sh <input.bam> <output.txt> [log_dir]

#Or it can be called from run_quality_control.sh.

set -euo pipefail

BAM="$1"
OUT="$2"

LOG_DIR="$(dirname "$OUT" | sed 's|^results/|logs/|')"
LOG="${LOG_DIR}/$(basename "$OUT" .txt).log"

echo "Creating output directory for flagstat results if it doesn't exist..."
mkdir -p "$(dirname "$OUT")"
mkdir -p "$LOG_DIR"

echo "Running samtools flagstat on $BAM..."
samtools flagstat "$BAM" > "$OUT" 2> "$LOG"

echo "SAMtools flagstat analysis done."
echo "Output: $OUT."
echo "Log: $LOG."