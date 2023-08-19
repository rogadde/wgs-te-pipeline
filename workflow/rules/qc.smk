def get_fastq(wildcards, read: str):
    return samples.loc[
        (wildcards.individual, wildcards.platform, wildcards.sample, wildcards.lane),
        read,
    ]


def get_fastqc_input(wildcards):
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


rule samtools_flagstat:
    input:
        rules.sambamba_sort.output,
    output:
        rules.sambamba_sort.output[0] + ".flagstat",
    log:
        rules.sambamba_sort.output[0] + ".flagstat.log",
    params:
        extra="",  # optional params string
    wrapper:
        "v2.1.1/bio/samtools/flagstat"


rule multiqc:
    input:
        expand(
            expand(
                rules.fastqc.output,
                zip,
                individual=samples.individual_id,
                sample=samples.sample_id,
                lane=samples.lane_id,
                platform=samples.platform,
                allow_missing=True,
            ),
            read=["r1", "r2"],
            trimmed=["raw", "trimmed"],
            allow_missing=True,
        ),
        expand(
            rules.samtools_flagstat.output,
            zip,
            individual=samples.individual_id,
            sample=samples.sample_id,
            lane=samples.lane_id,
            allow_missing=True,
        ),
        expand(
            rules.trimmomatic_pe.output,
            zip,
            individual=samples.individual_id,
            sample=samples.sample_id,
            lane=samples.lane_id,
            platform=samples.platform,
            allow_missing=True,
        ),
    output:
        "{outdir}/multiqc.html",
    params:
        extra="",  # Optional: extra parameters for multiqc.
        use_input_files_only=True,  # Optional, use only a.txt and don't search folder samtools_stats for files
    log:
        "{outdir}/multiqc.log",
    wrapper:
        "v1.28.0/bio/multiqc"
