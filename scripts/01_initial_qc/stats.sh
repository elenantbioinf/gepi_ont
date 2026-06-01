#!/usr/bin/env bash

# This script runs samtools stats on BAM files

#It can be executed directly:
#   bash stats.sh <input.bam> <output.txt>

#Or it can be called from run_quality_control.sh.

set -euo pipefail

BAM="$1"
OUT="$2"

LOG_DIR="$(dirname "$OUT" | sed 's|^results/|logs/|')"
LOG="${LOG_DIR}/$(basename "$OUT" .txt).log"

echo "Creating output directory for stats results if it doesn't exist..."
mkdir -p "$(dirname "$OUT")"
mkdir -p "$LOG_DIR"

echo "Running samtools stats on $BAM..."
samtools stats "$BAM" > "$OUT" 2> "$LOG"

echo "SAMtools stats analysis done."
echo "Output: $OUT."
echo "Log: $LOG."