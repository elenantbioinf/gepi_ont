#!/usr/bin/env bash

#This script runs the complete quality control analysis 
#It calls: 
#  - flagstat.sh
#  - stats.sh
#  - mosdepth.sh
#  - nanoplot.sh

#Use: bash run_quality_control.sh <input.bam>

set -euo pipefail

BAM="$1"

SAMPLE="$(basename "${BAM}" .bam)"

SCRIPT_DIR="scripts/01_initial_qc"

OUTDIR="results/01_initial_qc/${SAMPLE}"

#Create output directory
mkdir -p "${OUTDIR}"

#Info messages
echo "###########################################"
echo "Running quality control for sample: ${SAMPLE}"
echo "Input BAM: ${BAM}"
echo "Output directory: ${OUTDIR}"
echo "###########################################"

#Run flagstat
echo "------------------------------------------"  
echo "[INFO] Running flagstat analysis"

bash "${SCRIPT_DIR}/flagstat.sh" \
    "${BAM}" \
    "${OUTDIR}/samtools/${SAMPLE}_flagstat.txt"

echo "[INFO] Flagstat analysis completed."

#Run stats
echo "------------------------------------------"  
echo "[INFO] Running stats analysis"

bash "${SCRIPT_DIR}/stats.sh" \
    "${BAM}" \
    "${OUTDIR}/samtools/${SAMPLE}_stats.txt"

echo "[INFO] Stats analysis completed."

#Run mosdepth
echo "------------------------------------------"  
echo "[INFO] Running mosdepth analysis"

bash "${SCRIPT_DIR}/mosdepth.sh" \
    "${BAM}" \
    "${OUTDIR}/mosdepth/${SAMPLE}"

echo "[INFO] Mosdepth analysis completed."

#Run nanoplot
echo "------------------------------------------"  
echo "[INFO] Running NanoPlot analysis"

bash "${SCRIPT_DIR}/nanoplot.sh" \
    "${BAM}" \
    "${OUTDIR}/nanoplot"

echo "[INFO] NanoPlot analysis completed."

#Final message
echo "###########################################"
echo "Quality control completed for sample: ${SAMPLE}"
echo "Results are in: ${OUTDIR}"
echo "###########################################"