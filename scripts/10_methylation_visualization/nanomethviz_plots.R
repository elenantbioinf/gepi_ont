#!/usr/bin/env Rscript

#This script generates methylation plots using NanoMethViz from haplotagged BAM file

#It reads:
#   - A sample table with the BAM haplotagged files and its paths
#   - A target table with the genes or regions to plot
#   - A modified base code: m for 5mC or h for 5hmC

#To run it, it needs nanomethviz_plots_runner.sh, the script which will execute the
#process inside the Apptainer container of Bioconductor, where all the required
#libraries are. 

#It can be used in two ways: 

##Direct use with Apptainer
#   apptainer exec \
#       -B "$PWD":"$PWD" \
#       resources/containers/bioconductor_3.21.sif \
#       Rscript scripts/10_methylation_visualization/nanomethviz_plots.R

##Recommended use with runner script:
#   bash scripts/10_methylation_visualization/nanomethviz_plots_runner.sh


###############################
######### PREPARATION #########
###############################

#========Libraries=============

#Define local R library path
R_libs <- "resources/R_libs/nanomethviz_bioc3.21/"

#local R library to R libraries path
.libPaths(c(normalizePath(R_libs), .libPaths()))

#Load required libraries
suppressPackageStartupMessages({
  library(NanoMethViz)
  library(dplyr)
  library(readr)
  library(ggplot2)
})

#========Arguments and dependencies=============

#Define input files
samples_tsv <- "config/samples.tsv"
targets_tsv <- "config/nanomethviz_targets.tsv"

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

#==============Prepare BAM files=============

#Extract BAM file paths from samples table
bam_files <- samples$bam_haplotagged

for (bam_file in bam_files) {
  if (!file.exists(bam_file)){
    stop("[ERROR] BAM file not found: ", bam_file)
  }
  message("[INFO] Found BAM file: ", bam_file)
}

#================Exon annotation===============

#Creating exon annotation
exon_annot <- get_exons_hg38()

message("[INFO] Number of exon rows: ", nrow(exon_annot))


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


###############################
############ PLOTS ############
###############################

#================Outputs===============

#Define output directory
output_dir <- "results/10_methylation_visualization/nanomethviz"

#Create output directory if it doesn't exist
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

#================Generate Gene plot===============

#Iterate throught every row in targets
for (i in 1:nrow(targets)) {

  #Extract the information of the row
  target_id <- targets$target_id[i]
  target_type <- targets$target_type[i]
  symbol <- targets$symbol[i]

  #Keep only the target type gene
  if (target_type != "gene") next

  #Create output
  output_pdf <- file.path(output_dir, paste0(target_id, "_", mod_code, "_", "nanomethviz_plot_gene.pdf"))

  #Create plot gene
  gene_plot <- plot_gene(mbr, symbol)

  #Write the plot in the output file
  pdf(output_pdf)
  print(gene_plot)
  dev.off()

  message("[INFO] Gene plot saved: ", output_pdf)
}

#================Generate Region plot===============

#Iterate throught every row in targets
for (i in 1:nrow(targets)) {

  #Extract the information of the row
  target_id <- targets$target_id[i]
  target_type <- targets$target_type[i]
  chr <- targets$chr[i]
  start <- as.integer(targets$start[i])
  end <- as.integer(targets$end[i])

  #Keep only the target type region
  if (target_type != "region") next

  #Create output
  output_pdf <- file.path(output_dir, paste0(target_id, "_", mod_code, "_", "nanomethviz_plot_region.pdf"))

  #Create plot region
  region_plot <- plot_region(mbr, chr, start, end)

  #Write the plot in the output file
  pdf(output_pdf)
  print(region_plot)
  dev.off()

  message("[INFO] Region plot saved: ", output_pdf)
}