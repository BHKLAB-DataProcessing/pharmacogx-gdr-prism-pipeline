## ------------------- Parse Snakemake Object ------------------- ##
# Check if the "snakemake" object exists
# This snippet is run at the beginning of a snakemake run to setup the env
# Helps to load the workspace if the script is run independently or debugging
if (exists("snakemake")) {
    INPUT <- snakemake@input
    OUTPUT <- snakemake@output
    WILDCARDS <- snakemake@wildcards
    THREADS <- snakemake@threads

    # setup logger if log file is provided
    if (length(snakemake@log) > 0)
        sink(
            file = snakemake@log[[1]],
            append = FALSE,
            type = c("output", "message"),
            split = TRUE
        )

    # Assuming that this script is named after the rule
    # Saves the workspace to "resources/"preprocess_prism"
    file.path("resources", paste0(snakemake@rule, ".RData")) |>
        save.image()
} else {
    # If the snakemake object does not exist, load the workspace
    file.path("resources", "preprocess_prism.RData") |>
        load()
}

###############################################################################
# Load INPUT
###############################################################################
library(gDRimport)
library(gDRcore)
# Current PUBLIC PRISM data can be downloaded directly from:
# https://depmap.org/portal/data_page/?tab=allData
# Below the example for DepMap Public 24Q4
data_imported <- gDRimport::convert_LEVEL6_prism_to_gDR_input(
    prism_data_path = INPUT$prism_data_path,
    cell_line_data_path = INPUT$cell_line_data_path,
    treatment_data_path = INPUT$treatment_data_path,
    meta_data_path = INPUT$meta_data_path
)
data_imported_cleaned <- gDRcore::cleanup_metadata(data_imported)

###############################################################################
# Save OUTPUT
###############################################################################
# print(OUTPUT)
# print(data_imported_cleaned)

output_file <- file.path(OUTPUT$processed_data_path)

# make sure the output directory exists
dir.create(dirname(output_file), recursive = TRUE, showWarnings = FALSE)

data.table::fwrite(
    x = data_imported_cleaned,
    file = output_file,
)
