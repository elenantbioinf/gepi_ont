#!/usr/bin/env bash

# This script runs nanoplot on BAM files

#It can be executed directly:
#   bash nanoplot.sh <input.bam> <output_directory>

#Or it can be called from run_quality_control.sh.

set -euo pipefail

#Load project config
source "config/project_config.sh"

BAM="$1"
OUTDIR="$2"

SAMPLE="$(basename "$BAM" .bam)"

LOG_DIR="${INITIAL_QC_LOGS_DIR}/${SAMPLE}/nanoplot"
LOG="${LOG_DIR}/${SAMPLE}_nanoplot.log"

echo "Creating output directory if it doesn't exist..."
mkdir -p "$OUTDIR"
mkdir -p "$LOG_DIR"

echo "Running NanoPlot on $BAM..."
NanoPlot --bam "$BAM" -o "$OUTDIR" -p "$SAMPLE" 2> "$LOG"

echo "NanoPlot analysis done."
echo "Output directory: $OUTDIR."
echo "Log: $LOG."