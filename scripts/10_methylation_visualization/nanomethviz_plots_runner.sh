#!/usr/bin/env bash

#This script runs nanomethviz_plots.R inside the Bioconductor Apptainer container.

#Use: bash scripts/10_methylation_visualization/nanomethviz_plots_runner.sh

set -euo pipefail

CONTAINER="resources/containers/bioconductor_3.21.sif"
RSCRIPT="scripts/10_methylation_visualization/nanomethviz_plots.R"

LOG_DIR="logs/10_methylation_visualization"
LOG="${LOG_DIR}/nanomethviz_plots.log"

mkdir -p "$LOG_DIR"

apptainer exec \
  -B "$PWD":"$PWD" \
  "$CONTAINER" \
  Rscript "$RSCRIPT" \
  > "$LOG" 2>&1

echo "NanoMethViz plots completed."
echo "Log: $LOG"