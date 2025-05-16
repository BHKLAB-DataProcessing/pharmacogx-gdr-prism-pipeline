import os
from pathlib import Path
from rich import print
import pandas as pd
import requests
from tqdm import tqdm

RAWDATA = Path(os.environ['RAWDATA'])
if not RAWDATA.exists():
    raise FileNotFoundError(
        f"Please set the environment variable `RAWDATA` to a valid path."
    )

METADATA = Path(os.environ['METADATA'])
if not METADATA.exists():
    raise FileNotFoundError(
        f"Please set the environment variable `METADATA` to a valid path."
    )

# Create the directory for the depmap indices
depmap_dir = METADATA / 'depmap-indices'
depmap_dir.mkdir(parents=True, exist_ok=True)

depmap_index = pd.read_csv('https://depmap.org/portal/api/download/files')

# Get all the `PRISM` related data

releases = [
	'PRISM Repurposing Public 24Q2',
	'PRISM Repurposing 20Q2',
	'PRISM Repurposing 19Q3 Primary Screen',
	'PRISM Repurposing 19Q4',
	'PRISM Repurposing Public 23Q2',
]
filtered_index = depmap_index[depmap_index['release'].isin(releases)]


# Also get the row where 'filename'== `Model.csv` file and 'release' == 'DepMap Public 24Q2'
filtered_index = pd.concat([
    filtered_index,
    depmap_index[
        (depmap_index['filename'] == 'Model.csv')
        & (depmap_index['release'] == 'DepMap Public 24Q2')
    ]
])

# # save filtered index
filtered_index.to_csv(depmap_dir / 'depmap_index_filtered.csv', index=False)

FILES_OF_INTEREST = [
    "Repurposing_Public_24Q2_Cell_Line_Meta_Data.csv",
    "Repurposing_Public_24Q2_Treatment_Meta_Data.csv",
    "Repurposing_Public_24Q2_LFC.csv",
    "Model.csv",
]


# get the files of interest from the 'filename' column
interested_index = filtered_index[filtered_index['filename'].isin(FILES_OF_INTEREST)]

download_dir = RAWDATA / 'depmap-data' 
download_dir.mkdir(parents=True, exist_ok=True)
filepaths = []
for row in interested_index.itertuples(index=False):

    filepath = download_dir / row.filename
    filepaths.append(filepath)

    if filepath.exists():
        print(f"[green]File {filepath} already exists.[/green]")
        continue

    print(f"[blue]Downloading {row.filename}...[/blue]")
    response = requests.get(row.url, stream=True)
    if response.status_code == 200:
        # Get total file size from headers if available
        total_size = int(response.headers.get('content-length', 0))

        temp_filepath = filepath.with_suffix('.part')
        with temp_filepath.open('wb') as f:
            with tqdm(
                desc=row.filename,
                total=total_size,
                unit='B',
                unit_scale=True,
                unit_divisor=1024,
            ) as pbar:
                for chunk in response.iter_content(chunk_size=8192):
                    if chunk:  # filter out keep-alive chunks
                        f.write(chunk)
                        pbar.update(len(chunk))
            
        # Rename the temporary file to the final filename
        temp_filepath.rename(filepath)
        print(f"[green]Downloaded {row.filename}.[/green]")

print(f"[blue]Downloaded {len(filepaths)} files.[/blue]")
print(f'{filepaths=}')