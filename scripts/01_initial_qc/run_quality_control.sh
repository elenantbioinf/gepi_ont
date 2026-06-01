#!/usr/bin/env bash

#This script runs the complete quality control analysis 
#It calls: 
#  - flagstat.sh
#  - stats.sh
#  - mosdepth.sh
#  - nanoplot.sh

#Use: bash run_quality_control.sh <input.bam> <analysis_mode>
#analysis_mode options are:
#   -"initial"
#   -"post_filtering"

set -euo pipefail

#Check arguments
if [[ "$#" -ne 2 ]]; then
    echo "[ERROR] Usage: bash run_quality_control.sh <input.bam> <analysis_mode>"
    echo "[ERROR] analysis_mode options: 'initial' or 'post_filtering'"
    exit 1
fi

#Load project config
source "config/project_config.sh"

#Input arguments
BAM="$1"
QC_MODE="$2"

#Get sample name from BAM file
SAMPLE="$(basename "${BAM}" .bam)"

#Select output directory based on QC mode

#If QC_MODE is "initial", results go to INITIAL_QC_RESULTS_DIR
if [[ "$QC_MODE" == "initial" ]]; then
    QC_RESULTS_DIR="${INITIAL_QC_RESULTS_DIR}"
    QC_LOGS_DIR="${INITIAL_QC_LOGS_DIR}"

#If it's "post_filtering", results go to POST_FILTERING_QC_RESULTS_DIR
elif [[ "$QC_MODE" == "post_filtering" ]]; then
    QC_RESULTS_DIR="${POST_FILTERING_QC_RESULTS_DIR}"
    QC_LOGS_DIR="${POST_FILTERING_QC_LOGS_DIR}"

#If it's neither, exit with error
else
    echo "[ERROR] Invalid QC mode: $QC_MODE."
    echo "[ERROR] Use 'initial' or 'post_filtering'."
    exit 1
fi

#Make QC_LOGS_DIR available to the individual QC scripts
export QC_LOGS_DIR

#Define output directory for this sample's QC results
OUTDIR="${QC_RESULTS_DIR}/${SAMPLE}"

#Create output directory
mkdir -p "${OUTDIR}"

#Info messages
echo "###########################################"
echo "Running quality control for sample: ${SAMPLE}"
echo "Input BAM: ${BAM}"
echo "QC mode: ${QC_MODE}"
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
echo "QC mode: ${QC_MODE}"
echo "Results directory: ${OUTDIR}"
echo "Logs directory: ${QC_LOGS_DIR}/${SAMPLE}"
echo "###########################################"