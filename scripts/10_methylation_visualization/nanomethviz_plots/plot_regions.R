#!/usr/bin/env Rscript

#This script generates a plot of methylation in the specific regions introduced in
#nanomethviz_targets.tsv

#It looks for region targets and plot only those

#Use:
#   apptainer exec \
#       -B "$PWD":"$PWD" \
#       resources/containers/bioconductor_3.21.sif \
#       Rscript scripts/10_methylation_visualization/nanomethviz_plots/plot_regions.R


source("scripts/10_methylation_visualization/nanomethviz_plots/nanomethviz_common.R")

###############################
######## REGION PLOTS #########
###############################

#Keep only region targets
region_targets <- targets %>% filter(target_type == "region")

#Stop if there are no region targets
if (nrow(region_targets) == 0) {
    stop("[ERROR] No region targets found in: ", targets_tsv)
}

#Define and generate region plot output directory
region_output_dir <- file.path(output_dir, "region")
dir.create(region_output_dir, recursive = TRUE, showWarnings = FALSE)

#Iterate throught every row in targets
for (i in 1:nrow(region_targets)) {

  #Extract the information of the row
  target_id <- region_targets$target_id[i]
  chr <- region_targets$chr[i]
  start <- as.integer(region_targets$start[i])
  end <- as.integer(region_targets$end[i])

  message("[INFO] Generating region plot for: ", target_id)

  #Define output pdf
  output_pdf <- file.path(region_output_dir, paste0(target_id, "_", mod_code, "_nanomethviz_plot_region.pdf"))

  #Create plot region
  region_plot <- plot_region(mbr, chr, start, end)

  #Write the plot in the output file
  pdf(output_pdf)
  print(region_plot)
  dev.off()

  message("---[FINISHED]--- Region plot saved: ", output_pdf)
}
