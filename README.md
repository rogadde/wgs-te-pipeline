# WGS-TE-Pipeline

[![Snakemake](https://img.shields.io/badge/snakemake-≥7.16.0-brightgreen.svg)](https://snakemake.github.io)
[![GitHub actions status](https://github.com/rogadde/wgs-te-pipeline/workflows/Tests/badge.svg?branch=main)](https://github.com/<owner>/<repo>/actions?query=branch%3Amain+workflow%3ATests)

A Snakemake workflow for calling germline TE insertions from WGS data.

## Setup

```bash
# install environment
conda env create -f environment.yaml -n wgs-te-pipeline

# install pre-commit hooks
pre-commit install

# Create test data
cd .test/ngs-test-data
snakemake wgs --cores 2 --use-conda --show-failed-logs

# run the test
cd ../..
snakemake all --directory .test --cores 2 --use-conda --show-failed-logs
```

## TODO: Setup

- Activate the environment: `conda activate <name>`
- Install precommits: `pre-commit install`
- Replace `<owner>` and `<repo>` everywhere in the template (also under .github/workflows) with the correct `<repo>` name and owning user or organization.
- Replace `<name>` with the workflow name (can be the same as `<repo>`).
- Replace `<description>` with a description of what the workflow does.

## TODO: Rules

Alt-aware alignment with BWA: https://github.com/lh3/bwa/blob/master/README-alt.md

1. Adapter trimming (wait for now until Mike adds data to server)
2. Get reference genome and index (can download from [1000genomes FTP](http://ftp.1000genomes.ebi.ac.uk/vol1/ftp/technical/reference/GRCh38_reference_genome/) or use BWA kit)
   - make a condition to check if test data is being used or not
3. Align reads with `bwa mem`
4. Conduct postprocessing with `bwa-postalt.js`
5. Sort, index, and remove duplicates with `samblaster`
6. Call non-reference TEs with `xTea`
