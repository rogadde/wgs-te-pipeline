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
workdir = Path(snakemake.output.script[0]).parent.parent.parent.resolve()

# make id_list
with tempfile.NamedTemporaryFile("w", delete=False) as tmpfile:
    tmpfile.write(snakemake.wildcards.individual)
    cmd = f"-i {tmpfile.name} "

if "10x" in snakemake.wildcards.platform:
    with tempfile.NamedTemporaryFile("w", delete=False) as tmpfile:
        for b, bx in zip(snakemake.input["10x_bam"], snakemake.input["10x_bx_bam"]):
            tmpfile.write(f"{snakemake.wildcards.individual}\t{b}\t{bx}\n")
        cmd += f"-x {tmpfile.name} "
else:
    cmd += "-x null "

if "illumina" in snakemake.wildcards.platform:
    with tempfile.NamedTemporaryFile("w", delete=False) as tmpfile:
        for b in snakemake.input["illumina_bam"]:
            tmpfile.write(f"{snakemake.wildcards.individual}\t{b}\n")
        cmd += f"-b {tmpfile.name} "
else:
    cmd += "-b null "

shell(
    "xtea "
    "{cmd} "
    "-r {snakemake.input.fa} "
    "-g {snakemake.input.gencode} "
    "-l {snakemake.input.rep_lib} "
    "-p {workdir} "
    "-f 5907 "
    "--blacklist {snakemake.input.rep_lib}/blacklist/hg38/sv_blacklist.bed "
    "-y {reptype} "
    "-n {snakemake.threads} "
    "--xtea $CONDA_PREFIX/lib "
)


os.remove("submit_calling_jobs_for_samples.sh")
