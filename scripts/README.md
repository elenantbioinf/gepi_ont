# Scripts

This directory contains all analysis scripts used in the project.

Pipeline scripts are designed to be run from the project root directory.

This means that before running any script, the user should be located in the main `met_ont/` directory:

```bash
cd /path/to/met_ont
```

Then scripts should be executed using their full relative path from the project root.

This convention keeps relative paths consistent and allows the main scripts to load the shared project configuration file: `source config/project_config.sh`