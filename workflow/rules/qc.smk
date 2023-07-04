def get_fastqc_input(wildcards):
    if is_paired_end(wildcards):
        if wildcards.trimmed == "raw":
            return (
                get_fastq(wildcards, "r2")
                if wildcards.read == "r1"
                else get_fastq(wildcards, "r2")
            )
        elif wildcards.trimmed == "trimmed":
            return (
                rules.trimmomatic_pe.output.r1
                if wildcards.read == "r1"
                else rules.trimmomatic_pe.output.r2
            )
    else:
        if wildcards.trimmed == "raw":
            return get_fastq(wildcards, "r1")
        elif wildcards.trimmed == "trimmed":
            return rules.trimmomatic_se.output.r1


rule fastqc:
    input:
        get_fastqc_input,
    output:
        html="{outdir}/fastqc/{platform}/{individual}/{sample}/{lane}_{read}_{trimmed}.html",
        # the suffix _fastqc.zip is necessary for multiqc to find the file.
        zip="{outdir}/fastqc/{platform}/{individual}/{sample}/{lane}_{read}_{trimmed}_fastqc.zip",
    params:
        "--quiet",
    log:
        "{outdir}/fastqc/{platform}/{individual}/{sample}/{lane}_{read}_{trimmed}.log",
    threads: 1
    wrapper:
        "v1.28.0/bio/fastqc"


# get fastqc output for all samples
fastqc_outputs = []
for s in samples.itertuples():
    for t in ["raw", "trimmed"]:
        for u in s.units:
            fastqc_outputs.append(
                f"{{outdir}}/fastqc/{s.platform}/{s.individual_id}/{s.sample_id}/{s.lane_id}_{u}_{t}_fastqc.zip"
            )


rule multiqc:
    input:
        fastqc_outputs,
    output:
        "{outdir}/multiqc.html",
    params:
        extra="",  # Optional: extra parameters for multiqc.
        use_input_files_only=True,  # Optional, use only a.txt and don't search folder samtools_stats for files
    log:
        "{outdir}/multiqc.log",
    wrapper:
        "v1.28.0/bio/multiqc"
