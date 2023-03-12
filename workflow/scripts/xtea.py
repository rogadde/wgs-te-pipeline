#!/usr/bin/env python
# Created on: 10/26/22, 1:59 PM
__author__ = "Michael Cuoco"


import tempfile, os
from pathlib import Path
from snakemake.shell import shell

# convert string reptype into int for xtea input
def get_reptype(rep: str):
    if rep == "L1":
        return 1
    elif rep == "Alu":
        return 2
    elif rep == "SVA":
        return 4
    elif rep == "HERV":
        return 8
    elif rep == "Mitochondrial":
        return 16


if type(snakemake.config["reptype"]) is str:
    reptype = get_reptype(snakemake.config["reptype"])
else:
    reptype = 0
    for rep in snakemake.config["reptype"]:
        reptype += get_reptype(rep)

# make full path
workdir = Path(snakemake.output[0]).parent.parent.parent.resolve()

with tempfile.NamedTemporaryFile() as bam_list:
    with tempfile.NamedTemporaryFile() as id_list:
        # create id and bam list files for xtea
        bam_list.write(f"{snakemake.wildcards.sample}\t{snakemake.input.bam}".encode())
        bam_list.seek(0)
        id_list.write(snakemake.wildcards.sample.encode())
        id_list.seek(0)

        # generate runscript
        shell(
            "xtea "
            "-b {bam_list.name} "
            "-i {id_list.name} "
            "-r {snakemake.input.fa} "
            "-g {snakemake.input.gencode} "
            "-l {snakemake.input.rep_lib} "
            "-p {workdir} "
            "-x null "
            "-f 5907 "
            "-y {reptype} "
            "-n {snakemake.threads} "
            "--xtea $CONDA_PREFIX/lib "
        )

os.remove("submit_calling_jobs_for_samples.sh")
