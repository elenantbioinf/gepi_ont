# Containers

This directory contains Singularity/Apptainer container images for tools that are executed through containers instead of Conda environments.

Singularity/Apptainer must be installed to run these tools.

Container images are not tracked by Git because they can be large. Only this README file is kept in the repository to document the expected container structure.

To download the required containers, run from the root of the project:

```bash
bash scripts/00_resources/download_containers.sh
```

This script downloads the following images if they are not already present:

`resources/containers/deepvariant_1.10.0.sif`
`resources/containers/vep.sif`
`resources/containers/bioconductor_3.21.sif`