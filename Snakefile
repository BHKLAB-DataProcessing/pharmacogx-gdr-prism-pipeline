import os
from pathlib import Path

METADATA = Path(os.environ.get("METADATA"))
RAWDATA = Path(os.environ.get("RAWDATA"))
PROCDATA = Path(os.environ.get("PROCDATA"))
LOGS = Path(os.environ.get("LOGS"))
SCRIPTS = Path(os.environ.get("SCRIPTS"))
RESULTS = Path(os.environ.get("RESULTS"))

depmap_dir = RAWDATA / 'depmap-data'
if (missing := [var for var in [METADATA, RAWDATA, PROCDATA, LOGS, SCRIPTS] if var is None]):
    raise ValueError(f"Missing environment variables: {missing}")

rule make_prism_MAE:
    input:
        processed_data_path = PROCDATA / 'prism_processed_data.csv',
    output:
        mae_path = RESULTS / 'prism_MAE.rds',
        temp_steps = directory(RESULTS / 'temp_steps'),
        extracted_assays = directory(RESULTS / 'extracted_assays.csv')
    script:
        SCRIPTS / 'make_prism_MAE.R'

rule preprocess_prism:
    input:
        prism_data_path = depmap_dir / 'Repurposing_Public_24Q2_LFC.csv',
        cell_line_data_path = depmap_dir / 'Repurposing_Public_24Q2_Cell_Line_Meta_Data.csv',
        treatment_data_path = depmap_dir / 'Repurposing_Public_24Q2_Treatment_Meta_Data.csv',
        meta_data_path = depmap_dir / 'Model.csv',
    output:
        processed_data_path = PROCDATA / 'prism_processed_data.csv',
    script:
        SCRIPTS / 'preprocess_prism.R'

