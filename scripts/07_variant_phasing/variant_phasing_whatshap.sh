#!/usr/bin/env bash

#This script performs variant phasing using WhatsHap.

#Use: bash variant_phasing_whatshap.sh -i <input_bam> -v <input_vcf> -c <caller_name>

set -euo pipefail

#Inizializate variables to avoid error with set -u
INPUT_BAM=""
INPUT_VCF=""
CALLER_NAME=""

#Define usage of the script
usage () {
    echo "scripts/07_variant_phasing/variant_phasing_whatshap.sh"
    echo ""
    echo "Usage: bash $0 -i <input_bam> -v <input_vcf> -c <caller_name>"
    echo ""
    echo "Description:"
    echo "  Run WhatsHap for variant phasing on an indexed ONT BAM file and a filtered VCF file."
    echo ""
    echo "Options:"
    echo "  -i  Input BAM file (marked duplicates)"
    echo "  -v  Input VCF file (filtered, PASS variants)"
    echo "  -c  Variant caller name (e.g., clair3, deepvariant)"
    echo "  -h  Display this help message and exit"
}

#Parse command-line options
while getopts ":i:v:c:h" opt; do
    case "${opt}" in
        i ) INPUT_BAM="${OPTARG}"
            ;;
        v ) INPUT_VCF="${OPTARG}"
            ;;
        c ) CALLER_NAME="${OPTARG}" 
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

#Check if the required arguments are provided
if [[ -z "${INPUT_BAM}" ]]; then
    echo "[ERROR] Missing required input BAM" >&2
    usage
    exit 1
fi

if [[ -z "${INPUT_VCF}" ]]; then
    echo "[ERROR] Missing required input VCF" >&2
    usage
    exit 1
fi

if [[ -z "${CALLER_NAME}" ]]; then
    echo "[ERROR] Missing required caller name" >&2
    usage
    exit 1
fi

#Check caller name
case "${CALLER_NAME}" in
    clair3|deepvariant )
        ;;
    * )
        echo "[ERROR] Invalid caller name: ${CALLER_NAME}" >&2
        echo "[ERROR] Accepted values: clair3 or deepvariant" >&2
        exit 1
        ;;
esac

#Load project config
source "${GEPI_ONT_CONFIG:-config/project_config.sh}"

#Check if the required files exist
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

#Check input VCF
if [[ ! -s "${INPUT_VCF}" ]]; then
    echo "[ERROR] Input VCF not found or empty:"
    echo "[ERROR] ${INPUT_VCF}"
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

#Sample name
SAMPLE_NAME=$(basename "$INPUT_VCF" _${CALLER_NAME}_pass.vcf.gz)

#Outputs and logs
OUTPUT_DIR="${PHASED_RESULTS_DIR}/${CALLER_NAME}/${SAMPLE_NAME}"
PHASED_VCF="${OUTPUT_DIR}/${SAMPLE_NAME}_${CALLER_NAME}_phased.vcf.gz"

LOG_FILE="${VARIANT_PHASING_LOGS_DIR}/${CALLER_NAME}/${SAMPLE_NAME}_${CALLER_NAME}_whatshap_phasing.log"

#Info messages
echo "###########################################"
echo "Running variant phasing with WhatsHap"
echo "Sample: ${SAMPLE_NAME}"
echo "Caller: ${CALLER_NAME}"
echo "Input BAM: ${INPUT_BAM}"
echo "Input VCF: ${INPUT_VCF}"
echo "###########################################"

echo "Creating output and log directories if they don't exist..."

mkdir -p "$OUTPUT_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

echo "Executing WhatsHap..."

whatshap phase \
    --reference "$REFERENCE_GENOME" \
    --ignore-read-groups \
    --indels \
    --tag=PS \
    -o "$PHASED_VCF" \
    "$INPUT_VCF" \
    "$INPUT_BAM" \
    > "$LOG_FILE" 2>&1

echo "Indexing phased VCF with tabix..."
tabix -f -p vcf "$PHASED_VCF" >> "$LOG_FILE" 2>&1

#Check if the output files were created successfully
if [[ ! -s "$PHASED_VCF" || ! -s "${PHASED_VCF}.tbi" ]]; then
    echo "[ERROR] Phased VCF or its index was not created successfully. Check the log file for details:"
    echo "[ERROR] ${LOG_FILE}"
    exit 1
fi 


#Final messages
echo "###########################################"
echo "Variant phasing completed"
echo "Phased VCF: ${PHASED_VCF}"
echo "Index file: ${PHASED_VCF}.tbi"
echo "Log file: ${LOG_FILE}"
echo "###########################################"
