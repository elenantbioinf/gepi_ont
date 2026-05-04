#!/usr/bin/env Rscript

#This script generates an aggregate methylation plot for the promoters

#Use:
#   apptainer exec \
#       -B "$PWD":"$PWD" \
#       resources/containers/bioconductor_3.21.sif \
#       Rscript scripts/10_methylation_visualization/nanomethviz_plots/plot_promoter_aggregate.R

source("scripts/10_methylation_visualization/nanomethviz_plots/nanomethviz_common.R")

###############################
## PROMOTER AGGREGATED PLOT ###
###############################

#Define promoters annotation
promoters_annot <- promoters(
    gene_annot_gr,
    upstream = 2000,
    downstream = 2000
)

#Keep only chr22 promoters
promoters_annot_chr22 <- promoters_annot[seqnames(promoters_annot) == "chr22"]

#Stop if there are no promoters in chr22
if (length(promoters_annot_chr22) == 0) {
  stop("[ERROR] No promoter regions found in chr22")
}

#Transform promoter GRanges to table for NanoMethViz
promoters_annot_chr22 <- tibble(
  chr = as.character(seqnames(promoters_annot_chr22)),
  start = start(promoters_annot_chr22),
  end = end(promoters_annot_chr22),
  strand = as.character(strand(promoters_annot_chr22))
)

#Define and create promoter plot directory
promoter_dir <- file.path(output_dir, "promoters")
dir.create(promoter_dir, recursive = TRUE, showWarnings = FALSE)

#Save promoter regions used
write_tsv(
  promoters_annot_chr22,
  file.path(promoter_dir, "chr22_promoters_used.tsv")
)

#Create output
output_pdf <- file.path(promoter_dir, paste0("chr22_promoters_", mod_code, "_nanomethviz_aggregate_plot.pdf"))

#Create promoters aggregate plot
message("[INFO] Generating promoter aggregate plot...")

promoters_plot <- plot_agg_regions(
    mbr,
    regions = promoters_annot_chr22,
    group_col = "group"
)

#Write plot
pdf(output_pdf)
print(promoters_plot)
dev.off()

message("---[FINISHED]--- Promoter aggregate plot saved: ", output_pdf)