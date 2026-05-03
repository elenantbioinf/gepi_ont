#!/usr/bin/env bash

#This script downloads the Apptainer/Singularity container images required by the pipeline.
#It must be run from the root of the project.

#Use: bash scripts/00_resources/download_containers.sh

set -euo pipefail

CONTAINER_DIR="resources/containers"

mkdir -p "$CONTAINER_DIR"

download_if_missing() {
  local output_file="$1"
  local image="$2"

  if [[ -f "$output_file" ]]; then
    echo "Container already exists, skipping: $output_file"
  else
    echo "Downloading: $image"
    apptainer pull "$output_file" "$image"
  fi
}

download_if_missing \
  "${CONTAINER_DIR}/deepvariant_1.10.0.sif" \
  "docker://google/deepvariant:1.10.0"

download_if_missing \
  "${CONTAINER_DIR}/vep.sif" \
  "docker://ensemblorg/ensembl-vep"

download_if_missing \
  "${CONTAINER_DIR}/bioconductor_3.21.sif" \
  "docker://bioconductor/bioconductor_docker:RELEASE_3_21"

echo "Container download completed."