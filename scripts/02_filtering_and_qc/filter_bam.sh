#!/usr/bin/env bash

# This script filters BAM files for methylation analysis:
# - keeps only primary alignments
# - keeps only alignments with MAPQ >= 20
# - keeps only reads with sequence length >= 1000 bp

# Use: bash filter_bam_for_methylation.sh <input.bam>

set -euo pipefail

BAM_RAW="$1"
BAM_FILTERED="data/processed/$(basename "$BAM_RAW" .bam)_filtered.bam"
LOG="logs/02_filtering/$(basename "$BAM_FILTERED" .bam).log"

echo "Creating output directory if it doesn't exist..."
mkdir -p "$(dirname "$BAM_FILTERED")"
mkdir -p logs/02_filtering

echo "Filtering $BAM_RAW for methylation analysis..."
samtools view -h -b \
    -F 2308 \
    -q 20 \
    -m 1000 \
    "$BAM_RAW" \
    -o "$BAM_FILTERED" 2> "$LOG"
echo "Filtering done."

echo "Indexing the filtered BAM file..."
samtools index "$BAM_FILTERED" 2>> "$LOG"
echo "Indexing done."

echo "Output: $BAM_FILTERED."
echo "Index: ${BAM_FILTERED}.bai."
echo "Log: $LOG."