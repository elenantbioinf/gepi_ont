#!/usr/bin/env Rscript

#This script installs the R/Bioconductor packages required for the NanoMethViz branch.
#It must be run inside the Bioconductor Apptainer container.

#Use:
#   mkdir -p logs/10_methylation_visualization
#   apptainer exec \
#     -B "$PWD":"$PWD" \
#     resources/containers/bioconductor_3.21.sif \
#     Rscript scripts/00_resources/install_nanomethviz_packages.R \
#     > logs/10_methylation_visualization/install_nanomethviz_packages.log \
#     2>&1

# Define project-local R library
r_lib <- "resources/R_libs/nanomethviz_bioc3.21"

# Create project-local R library if it does not exist
if (!dir.exists(r_lib)) {
  dir.create(r_lib, recursive = TRUE)
}

# Use project-local R library
.libPaths(r_lib)

# Install required packages
BiocManager::install(
  c(
    "NanoMethViz",
    "bsseq",
    "dmrseq",
    "edgeR",
    "limma",
    "plyranges",
    "TxDb.Hsapiens.UCSC.hg38.knownGene",
    "org.Hs.eg.db"
  ),
  ask = FALSE,
  update = FALSE
)

# Validate installation
library(NanoMethViz)
library(bsseq)
library(dmrseq)
library(edgeR)
library(limma)
library(plyranges)
library(TxDb.Hsapiens.UCSC.hg38.knownGene)
library(org.Hs.eg.db)

print(paste("NanoMethViz version:", packageVersion("NanoMethViz")))
print(paste("bsseq version:", packageVersion("bsseq")))
print(paste("dmrseq version:", packageVersion("dmrseq")))
print(paste("edgeR version:", packageVersion("edgeR")))
print(paste("limma version:", packageVersion("limma")))
print(paste("plyranges version:", packageVersion("plyranges")))
print(paste("TxDb.Hsapiens.UCSC.hg38.knownGene version:", packageVersion("TxDb.Hsapiens.UCSC.hg38.knownGene")))
print(paste("org.Hs.eg.db version:", packageVersion("org.Hs.eg.db")))
cat("\n")
print("NanoMethViz package installation completed.")