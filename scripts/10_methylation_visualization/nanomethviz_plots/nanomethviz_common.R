#!/usr/bin/env Rscript

#This script contains common utilities for NanoMethViz plotting

#This scripts will not executed directly

#It is loaded in individual script with source():
# - plot_genes.R
# - plot_regions.R
# - plot_cpg_island_aggregate.R
# - plot_promoter_aggregate.R


###############################
########## LIBRARIES ##########
###############################

#Define local R library path
r_libs <- "resources/R_libs/nanomethviz_bioc3.21/"

#local R library to R libraries path
.libPaths(c(normalizePath(r_libs), .libPaths()))

#Load required libraries
suppressPackageStartupMessages({
  library(NanoMethViz)
  library(dplyr)
  library(readr)
  library(ggplot2)
  library(GenomicFeatures)
  library(TxDb.Hsapiens.UCSC.hg38.knownGene)
  library(tibble)
})

###############################
######### INPUT SETUP #########
###############################

#Define input files
samples_tsv <- "config/visualization_nanomethviz/samples.tsv"
targets_tsv <- "config/visualization_nanomethviz/nanomethviz_targets.tsv"

#Check if input files exist
if (!file.exists(samples_tsv)) {
  stop("[ERROR] Sample table not found: ", samples_tsv)
}

if (!file.exists(targets_tsv)) {
  stop("[ERROR] Target table not found: ", targets_tsv)
}

#Define modified bases
mod_code <- "m"

#Transform input files in R tables
samples <- read_tsv(samples_tsv, show_col_types = FALSE)
targets <- read_tsv(targets_tsv, show_col_types = FALSE)

###############################
############ OUTPUT ###########
###############################

#Define output directory
output_dir <- "results/10_methylation_visualization/nanomethviz"

#Create if it does not exist
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

###############################
###### PREPARE BAM FILES ######
###############################

#Extract BAM file paths from samples table
bam_files <- samples$bam_haplotagged

for (bam_file in bam_files) {
  if (!file.exists(bam_file)){
    stop("[ERROR] BAM file not found: ", bam_file)
  }
  message("[INFO] Found BAM file: ", bam_file)
}

###############################
######### ANNOTATIONS #########
###############################

#Creating exon annotation
exon_annot <- get_exons_hg38()

message("[INFO] Number of exon rows: ", nrow(exon_annot))

#Creating gene annotation
gene_annot <- exons_to_genes(exon_annot)
gene_annot_gr <- as(gene_annot, "GRanges")

message("[INFO] Number of gene rows: ", nrow(gene_annot))

###############################
##### NANOMETHVIZ OBJECTS #####
###############################

#Create ModBamFiles object from haplotagged BAM files
mod_bam_files <- ModBamFiles(
  paths = bam_files, samples = samples$sample
)

#Create ModBamResults object
mbr <- ModBamResult(
  methy = mod_bam_files,
  samples = samples,
  exons = exon_annot,
  mod_code = mod_code
)


