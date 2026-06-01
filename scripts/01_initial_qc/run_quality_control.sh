#!/usr/bin/env bash

#This script runs the complete quality control analysis 
#It calls: 
#  - flagstat.sh
#  - stats.sh
#  - mosdepth.sh
#  - nanoplot.sh

#Use: bash run_quality_control.sh <input.bam>

set -euo pipefail

#Load project config
source "config/project_config.sh"

BAM="$1"

SAMPLE="$(basename "${BAM}" .bam)"

OUTDIR="${INITIAL_QC_RESULTS_DIR}/${SAMPLE}"

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

bash "${INITIAL_QC_SCRIPTS_DIR}/flagstat.sh" \
    "${BAM}" \
    "${OUTDIR}/samtools/${SAMPLE}_flagstat.txt"

echo "[INFO] Flagstat analysis completed."

#Run stats
echo "------------------------------------------"  
echo "[INFO] Running stats analysis"

bash "${INITIAL_QC_SCRIPTS_DIR}/stats.sh" \
    "${BAM}" \
    "${OUTDIR}/samtools/${SAMPLE}_stats.txt"

echo "[INFO] Stats analysis completed."

#Run mosdepth
echo "------------------------------------------"  
echo "[INFO] Running mosdepth analysis"

bash "${INITIAL_QC_SCRIPTS_DIR}/mosdepth.sh" \
    "${BAM}" \
    "${OUTDIR}/mosdepth/${SAMPLE}"

echo "[INFO] Mosdepth analysis completed."

#Run nanoplot
echo "------------------------------------------"  
echo "[INFO] Running NanoPlot analysis"

bash "${INITIAL_QC_SCRIPTS_DIR}/nanoplot.sh" \
    "${BAM}" \
    "${OUTDIR}/nanoplot"

echo "[INFO] NanoPlot analysis completed."

#Final message
echo "###########################################"
echo "Quality control completed for sample: ${SAMPLE}"
echo "Results are in: ${OUTDIR}"
echo "###########################################"