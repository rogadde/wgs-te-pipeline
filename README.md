# WGS-TE-Pipeline

[![Snakemake](https://img.shields.io/badge/snakemake-≥7.16.0-brightgreen.svg)](https://snakemake.github.io)
[![GitHub actions status](https://github.com/rogadde/wgs-te-pipeline/workflows/Tests/badge.svg?branch=main)](https://github.com/<owner>/<repo>/actions?query=branch%3Amain+workflow%3ATests)

A Snakemake workflow for calling germline TE insertions from WGS data.

## Setup

```bash
# install environment
conda env create -f environment.yaml -n wgs-te-pipeline

# Create test data
cd .test/ngs-test-data
snakemake wgs --cores 2 --use-conda --show-failed-logs

# run the test
cd ../..
snakemake all --directory .test --cores 2 --use-conda --show-failed-logs --configfile .test/config/hg38.yaml
```

## Limitations

1. xTea cannot call TE insertions from single-end reads, but you can use this pipeline to qc and map these reads

## TODO:

- [ ] add option for somatic TE calling
- [ ] simplify samplesheet index
