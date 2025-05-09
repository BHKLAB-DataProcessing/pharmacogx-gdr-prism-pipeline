import os
from pathlib import Path

import pandas as pd

METADATA = Path(os.environ['METADATA'])
depmap_dir = METADATA / 'depmap-indices'
depmap_dir.mkdir(parents=True, exist_ok=True)

depmap_index = pd.read_csv('https://depmap.org/portal/api/download/files')

# prism_indies = list(filter(lambda x: "prism" in x.lower(), df["release"].unique().tolist()))
releases = [
	'PRISM Repurposing Public 24Q2',
	'PRISM Repurposing 20Q2',
	'PRISM Repurposing 19Q3 Primary Screen',
	'PRISM Repurposing 19Q4',
	'PRISM Repurposing Public 23Q2',
	'DepMap Public 24Q4',
]

filtered_index = depmap_index[depmap_index['release'].isin(releases)]

# save full index
depmap_index.to_csv(depmap_dir / 'depmap_index.csv', index=False)

# save filtered index
filtered_index.to_csv(depmap_dir / 'depmap_index_filtered.csv', index=False)


def sanitize_filename(filename: str) -> str:
	"""Sanitize filename by replacing spaces with underscores and removing special characters."""
	return filename.replace(' ', '_').replace('/', '_').replace(':', '_')


# save each release index
for release in releases:
	release_index = depmap_index[depmap_index['release'] == release]
	release_index.to_csv(
		depmap_dir / f'depmap_index__release-{sanitize_filename(release)}.csv',
		index=False,
	)
