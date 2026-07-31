#!/usr/bin/env bash

#This script runs Clair3 for variant calling on an indexed ONT BAM file

#Use: bash variant_calling_clair3.sh -i <input.bam>

set -euo pipefail

#Inizializate variables to avoid error with set -u
INPUT_BAM=""

#Define usage of the script
usage () {
    echo "scripts/06_variant_calling/variant_calling_clair3.sh"
    echo ""
    echo "Usage: bash $0 -i <input.bam>"
    echo ""
    echo "Description:"
    echo "  Run Clair3 for germline SNV/indel calling on an indexed ONT BAM file."
    echo ""
    echo "Options:"
    echo "  -i  Input BAM file"
    echo "  -h  Display this help message and exit"
}

#Parse command-line options
while getopts ":i:h" opt; do
    case "${opt}" in
        i ) INPUT_BAM="${OPTARG}"
            ;;
        h ) usage
            exit 0
            ;;
        \? )
            echo "[ERROR] Invalid option: -${OPTARG}" >&2
            usage
            exit 1
            ;;
        : )
            echo "[ERROR] Option -${OPTARG} requires an argument." >&2
            usage
            exit 1
            ;;
    esac
done

#Check if the required argument is provided
if [[ -z "${INPUT_BAM}" ]]; then
    echo "[ERROR] Missing required input BAM." >&2
    usage
    exit 1
fi

#Load project config
source "${GEPI_ONT_CONFIG:-config/project_config.sh}"

#Check if the required files exists 
#Check input BAM
if [[ ! -s "${INPUT_BAM}" ]]; then
    echo "[ERROR] Input BAM not found or empty:"
    echo "[ERROR] ${INPUT_BAM}"
    exit 1
fi

#Check BAM index
if [[ ! -s "${INPUT_BAM}.bai" && \
      ! -s "${INPUT_BAM%.bam}.bai" ]]; then
    echo "[ERROR] BAM index not found for:"
    echo "[ERROR] ${INPUT_BAM}"
    exit 1
fi

#Check reference genome
if [[ ! -s "${REFERENCE_GENOME}" ]]; then
    echo "[ERROR] Reference genome not found or empty:"
    echo "[ERROR] ${REFERENCE_GENOME}"
    exit 1
fi

#Check reference index
if [[ ! -s "${REFERENCE_GENOME}.fai" ]]; then
    echo "[ERROR] Reference genome index not found:"
    echo "[ERROR] ${REFERENCE_GENOME}.fai"
    exit 1
fi

#Check Clair3 model
if [[ ! -d "${CLAIR3_MODEL}" ]]; then
    echo "[ERROR] Clair3 model directory not found:"
    echo "[ERROR] ${CLAIR3_MODEL}"
    exit 1
fi

#Sample name
SAMPLE="$(basename "$INPUT_BAM" .bam)"

#Output and log directory
OUTDIR="${CLAIR3_RESULTS_DIR}/${SAMPLE}"
LOG="${CLAIR3_LOGS_DIR}/${SAMPLE}_clair3.log"

#Final renamed outputs
FINAL_VCF="${OUTDIR}/${SAMPLE}_clair3.vcf.gz"
FINAL_TBI="${FINAL_VCF}.tbi"

#Original Clair3 outputs
CLAIR3_VCF="${OUTDIR}/merge_output.vcf.gz"
CLAIR3_TBI="${CLAIR3_VCF}.tbi"

#Skip execution if final output exists
if [[ -s "${FINAL_VCF}" && -s "${FINAL_TBI}" ]]; then
    echo "[SKIP] Clair3 results already exist:"
    echo "[SKIP] ${FINAL_VCF}"
    exit 0
fi

#Creating output directory if it doesn't exist
mkdir -p "$OUTDIR"
mkdir -p "$CLAIR3_LOGS_DIR"

#Information
echo "###########################################"
echo "Running Clair3"
echo "Sample: ${SAMPLE}"
echo "Input BAM: ${INPUT_BAM}"
echo "Reference: ${REFERENCE_GENOME}"
echo "Model: ${CLAIR3_MODEL}"
echo "Threads: ${CLAIR3_THREADS}"
echo "Platform: ${CLAIR3_PLATFORM}"
echo "Contig: ${CLAIR3_CONTIG:-all supported contigs}"
echo "Output directory: ${OUTDIR}"
echo "Log: ${LOG}"
echo "###########################################"

#Clair3 execution

#If you define a region of analysis in the config file
if  [[ -n "${CLAIR3_CONTIG}" ]]; then

    run_clair3.sh \
        --bam_fn="$INPUT_BAM" \
        --ref_fn="$REFERENCE_GENOME" \
        --model_path="$CLAIR3_MODEL" \
        --threads="$CLAIR3_THREADS" \
        --platform="$CLAIR3_PLATFORM" \
        --sample_name="${SAMPLE}" \
        --output="$OUTDIR" \
        --ctg_name="${CLAIR3_CONTIG}" \
        > "$LOG" 2>&1

#If you want to analyse all the sample
else

    run_clair3.sh \
        --bam_fn="$INPUT_BAM" \
        --ref_fn="$REFERENCE_GENOME" \
        --model_path="$CLAIR3_MODEL" \
        --threads="$CLAIR3_THREADS" \
        --platform="$CLAIR3_PLATFORM" \
        --sample_name="${SAMPLE}" \
        --output="$OUTDIR" \
        > "$LOG" 2>&1
fi

#Check if the output exists
if [[ ! -s "${CLAIR3_VCF}" ]]; then
    echo "[ERROR] Clair3 did not generate:"
    echo "[ERROR] ${CLAIR3_VCF}"
    echo "[ERROR] Review the log:"
    echo "[ERROR] ${LOG}"
    exit 1
fi

if [[ ! -s "${CLAIR3_TBI}" ]]; then
    echo "[ERROR] Clair3 did not generate:"
    echo "[ERROR] ${CLAIR3_TBI}"
    echo "[ERROR] Review the log:"
    echo "[ERROR] ${LOG}"
    exit 1
fi

#Rename final outouts
mv "${OUTDIR}/merge_output.vcf.gz" "$FINAL_VCF"
mv "${OUTDIR}/merge_output.vcf.gz.tbi" "$FINAL_TBI"

echo "###########################################"
echo "Clair3 run complete."
echo "Results saved to $FINAL_VCF and $FINAL_TBI."
echo "Log saved to $LOG."
echo "###########################################"


