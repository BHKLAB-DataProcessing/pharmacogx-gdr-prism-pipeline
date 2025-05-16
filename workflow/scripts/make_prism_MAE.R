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
    # Saves the workspace to "resources/"make_prism_MAE"
    file.path("resources", paste0(snakemake@rule, ".RData")) |>
        save.image()
} else {
    # If the snakemake object does not exist, load the workspace
    file.path("resources", "make_prism_MAE.RData") |>
        load()
}

###############################################################################
# Load INPUT
###############################################################################

data_imported <- data.table::fread(INPUT$processed_data_path)

# subset for now
data_imported <- data_imported[clid == unique(clid)[1]]

###############################################################################
# Main Script
###############################################################################
# make temp directory
message("Starting to run the pipeline")
dir.create(OUTPUT$temp_steps, recursive = TRUE, showWarnings = FALSE)
mae <- gDRcore::runDrugResponseProcessingPipeline(
    data_imported,
    data_dir = OUTPUT$temp_steps
)

## ------------------------------------------------------------------------- ##
# Do something
message("Extracting data from MAE")

_ <- sapply(names(mae), function(se_name) {
    se <- mae[[se_name]]
    assay_names <- SummarizedExperiment::assayNames(se)
    output_dir <- file.path(dirname(OUTPUT$extracted_assays), se_name)
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

    dt_list <- lapply(assay_names, \(a) gDRutils::convert_se_assay_to_dt(se, a))

    Map(
        \(dt, assay)
            data.table::fwrite(
                dt,
                file = file.path(output_dir, paste0(assay, ".csv")),
                row.names = FALSE
            ),
        dt_list,
        assay_names
    )
    return(dt_list)
})

###############################################################################
# Save OUTPUT
###############################################################################
