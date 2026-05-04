#!/usr/bin/env bash

#This script runs nanomethviz plots inside the Bioconductor Apptainer container.

#Use: bash scripts/10_methylation_visualization/nanomethviz_plots_runner.sh <type_plot>

#Available plot types:
#  - genes
#  - regions
#  - cpg_island
#  - promoters
#  - all

set -euo pipefail

PLOT_TYPE="${1:-}"

CONTAINER="resources/containers/bioconductor_3.21.sif"

SCRIPT_DIR="scripts/10_methylation_visualization/nanomethviz_plots"

LOG_DIR="logs/10_methylation_visualization/nanomethviz_plots"

mkdir -p "$LOG_DIR"

#Create a function to run plots
run_plot() {
  local script="$1"
  local log="$2"

  echo "[INFO] Running $script..."

  apptainer exec \
    -B "$PWD":"$PWD" \
    "$CONTAINER" \
    Rscript "${SCRIPT_DIR}/${script}" \
    > "${LOG_DIR}/${log}" 2>&1

  echo "---[FINISHED]--- $script"
  echo "[INFO] Log: ${LOG_DIR}/${log}"
}

#If the argument is "genes"
if [[ "$PLOT_TYPE" == "genes" ]]; then

  run_plot "plot_genes.R" "plot_genes.log"

#If the argument is "regions"
elif [[ "$PLOT_TYPE" == "regions" ]]; then

  run_plot "plot_regions.R" "plot_regions.log"

#If the argument is "cpg_island"
elif [[ "$PLOT_TYPE" == "cpg_island" ]]; then

  run_plot "plot_cpg_island_aggregate.R" "plot_cpg_island_aggregate.log"

#If the argument is "promoters"
elif [[ "$PLOT_TYPE" == "promoters" ]]; then

  run_plot "plot_promoter_aggregate.R" "plot_promoter_aggregate.log"

#If the argument is "all"
elif [[ "$PLOT_TYPE" == "all" ]]; then

  run_plot "plot_genes.R" "plot_genes.log"
  run_plot "plot_regions.R" "plot_regions.log"
  run_plot "plot_cpg_island_aggregate.R" "plot_cpg_island_aggregate.log"
  run_plot "plot_promoter_aggregate.R" "plot_promoter_aggregate.log"

else

  echo "[ERROR] Invalid or missing plot type."
  echo ""
  echo "Use one of:"
  echo "  - genes"
  echo "  - regions"
  echo "  - cpg_island"
  echo "  - promoters"
  echo "  - all"
  exit 1

fi