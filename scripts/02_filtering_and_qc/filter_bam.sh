#!/usr/bin/env bash

# This script filters BAM files for methylation analysis:
# - keeps only primary alignments
# - keeps only alignments with MAPQ >= FILTER_MIN_MAPQ
# - keeps only reads with sequence length >= FILTER_MIN_READ_LENGTH

# Use: bash filter_bam.sh <input.bam>

set -euo pipefail

#Load project config
source "${MET_ONT_CONFIG:-config/project_config.sh}"

BAM_RAW="$1"

SAMPLE="$(basename "${BAM_RAW}" .bam)"

BAM_FILTERED="${FILTERED_BAM_DIR}/${SAMPLE}/${SAMPLE}_filtered.bam"

LOG="${FILTERING_LOGS_DIR}/${SAMPLE}/${SAMPLE}_filtered.log"

#Info messages
echo "###########################################"
echo "Running BAM filtering for sample: ${SAMPLE}"
echo "Input BAM: ${BAM_RAW}"
echo "Output directory: ${FILTERED_BAM_DIR}/${SAMPLE}"
echo "###########################################"

echo "Creating output directory if it doesn't exist..."
mkdir -p "$(dirname "$BAM_FILTERED")"
mkdir -p "$(dirname "$LOG")"

echo "Filtering $BAM_RAW for methylation analysis..."
echo "Minimum MAPQ: ${FILTER_MIN_MAPQ}"
echo "Minimum read length: ${FILTER_MIN_READ_LENGTH}"
echo "Excluded flags: ${FILTER_EXCLUDE_FLAGS}"

samtools view -h -b \
    -F "${FILTER_EXCLUDE_FLAGS}" \
    -q "${FILTER_MIN_MAPQ}" \
    -m "${FILTER_MIN_READ_LENGTH}" \
    "$BAM_RAW" \
    -o "$BAM_FILTERED" 2> "$LOG"
echo "Filtering done."

echo "Indexing the filtered BAM file..."
samtools index "$BAM_FILTERED" 2>> "$LOG"
echo "Indexing done."

#Final message
echo "###########################################"
echo "Output: $BAM_FILTERED."
echo "Index: ${BAM_FILTERED}.bai."
echo "Log: $LOG."
echo "###########################################"