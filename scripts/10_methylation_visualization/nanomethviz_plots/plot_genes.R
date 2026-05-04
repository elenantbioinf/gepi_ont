#!/usr/bin/env Rscript

#This script generates a plot of methylation in the specific genes introduced in
#nanomethviz_targets.tsv

#It looks for gene targets and plot only those

#Use:
#   apptainer exec \
#       -B "$PWD":"$PWD" \
#       resources/containers/bioconductor_3.21.sif \
#       Rscript scripts/10_methylation_visualization/nanomethviz_plots/plot_genes.R


source("scripts/10_methylation_visualization/nanomethviz_plots/nanomethviz_common.R")

###############################
######### GENE PLOTS ##########
###############################

#Keep only gene targets
gene_targets <- targets %>% filter(target_type == "gene")

#Stop if there are no gene targets
if (nrow(gene_targets) == 0) {
    stop("[ERROR] No gene targets found in: ", targets_tsv)
}

#Define and generate gene plot output directory
gene_output_dir <- file.path(output_dir, "gene")
dir.create(gene_output_dir, recursive = TRUE, showWarnings = FALSE)

#Iterate throught every row in targets
for (i in 1:nrow(gene_targets)) {

  #Extract the information of the row
  target_id <- gene_targets$target_id[i]
  symbol <- gene_targets$symbol[i]

  message("[INFO] Generating gene plot for: ", symbol)

  #Define output pdf
  output_pdf <- file.path(gene_output_dir, paste0(target_id, "_", mod_code, "_nanomethviz_plot_gene.pdf"))

  #Create plot gene
  gene_plot <- plot_gene(mbr, symbol)

  #Write the plot in the output file
  pdf(output_pdf)
  print(gene_plot)
  dev.off()

  message("---[FINISHED]--- Gene plot saved: ", output_pdf)
}
