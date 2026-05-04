#!/usr/bin/env Rscript

#This script generates an aggregate methylation plot for the cpg islands 

#Use:
#   apptainer exec \
#       -B "$PWD":"$PWD" \
#       resources/containers/bioconductor_3.21.sif \
#       Rscript scripts/10_methylation_visualization/nanomethviz_plots/plot_cpg_island_aggregate.R

source("scripts/10_methylation_visualization/nanomethviz_plots/nanomethviz_common.R")

###############################
# CpG ISLAND AGGREGATED PLOT ##
###############################

#Get CpG island annotation for hg38
cgi_annot <- get_cgi_hg38()

cgi_annot_chr22 <- cgi_annot %>% filter(chr == "chr22")

if (nrow(cgi_annot_chr22) == 0) {
  stop("[ERROR] No CpG islands found in chr22")
}

message("[INFO] Number of hg38 CpG islands: ", nrow(cgi_annot))
message("[INFO] Number of chr22 CpG islands: ", nrow(cgi_annot_chr22))

#Define and generate cpg island plot directory
cgi_directory <- file.path(output_dir, "cpg_island")
dir.create(cgi_directory, recursive = TRUE, showWarnings = FALSE)

#Save CpG island information
write_tsv(cgi_annot_chr22, file.path(cgi_directory, "chr22_cpg_islands_used.tsv"))

#Create output
output_pdf <- file.path(cgi_directory, paste0("chr22_cpg_islands_", mod_code, "_nanomethviz_aggregate_plot.pdf"))

#Create CpG island aggregate plot
message("[INFO] Generating CpG island aggregate plot...")
cgi_plot <- plot_agg_regions(
  mbr,
  regions = cgi_annot_chr22,
  group_col = "group"
)

#Write the plot in the output file
pdf(output_pdf)
print(cgi_plot)
dev.off()


message("---[FINISHED]--- CpG island aggregate plot saved: ", output_pdf)