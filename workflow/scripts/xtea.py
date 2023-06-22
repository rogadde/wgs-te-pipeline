#!/usr/bin/env python
# Created on: 10/26/22, 1:59 PM
__author__ = "Michael Cuoco"


import tempfile, os, sys
from pathlib import Path
from snakemake.shell import shell

sys.stderr = open(snakemake.log[0], "w")


def get_reptype(rep: str):
    "convert string reptype into int for xtea input"
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


# make reptype argument for xTea
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

# handle bams for 10x and/or illumina
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

# handle different genomes
if "38" in snakemake.config["genome"]["name"]:
    pyscript = f"{snakemake.input.xtea}/xtea/gnrt_pipeline_local_v38.py "
elif "chm13" in snakemake.config["genome"]["name"]:
    pyscript = f"{snakemake.input.xtea}/xtea/gnrt_pipeline_local_chm13.py "
else:
    ValueError("Genome {} not supported".format(snakemake.config["genome"]["name"]))

shell(
    "python "
    "{pyscript} "
    "{cmd} "
    "-r {snakemake.input.fa} "
    "-g {snakemake.input.gencode} "
    "-l {snakemake.input.rep_lib} "
    "-p {workdir} "
    "-f 5907 "
    "-y {reptype} "
    "-n {snakemake.threads} "
    "--xtea {snakemake.input.xtea}/xtea "
)


os.remove("submit_calling_jobs_for_samples.sh")

sys.stderr.close()
