#!/usr/bin/env python
# Created on: 10/26/22, 1:59 PM
__author__ = "Michael Cuoco"

from pathlib import Path
import os
from snakemake.shell import shell

# get path to fastq dir
fastq_dir = Path(snakemake.input["fastqs"][0]).parent
for fq in snakemake.input["fastqs"]:
    assert Path(fq).parent == fastq_dir, "All fastqs must be in the same directory"

fastq_dir = str(fastq_dir)

ref_dir = snakemake.input["ref"]

shell(
    "{snakemake.input.longranger}/longranger align "
    "--id={snakemake.wildcards.sample} "
    "--reference={ref_dir} "
    "--fastqs={fastq_dir} "
    "--localcores={snakemake.threads} "
    "--disable-ui "
)

outdir = str(Path(snakemake.output.bam).parent.parent)
os.makedirs(outdir, exist_ok=True)

shell("mv {snakemake.wildcards.sample} {outdir}")
