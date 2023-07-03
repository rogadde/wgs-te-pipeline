def get_fastqc_input(wildcards):
    if is_paired_end(wildcards.individual, wildcards.sample, wildcards.lane):
        r1 = samples.loc[
            (wildcards.individual, "illumina", wildcards.sample, wildcards.lane), "r1"
        ]
        r2 = samples.loc[
            (wildcards.individual, "illumina", wildcards.sample, wildcards.lane), "r2"
        ]
        return r1 if wildcards.read == "r1" else r2
    else:
        return samples.loc[
            (wildcards.individual, "illumina", wildcards.sample, wildcards.lane), "r1"
        ]


rule fastqc:
    input:
        get_fastqc_input,
    output:
        html="{outdir}/fastqc/illumina/{individual}/{sample}/{lane}_{read}.html",
        # the suffix _fastqc.zip is necessary for multiqc to find the file.
        zip="{outdir}/fastqc/illumina/{individual}/{sample}/{lane}_{read}_fastqc.zip",
    params:
        "--quiet",
    log:
        "{outdir}/fastqc/illumina/{individual}/{sample}/{lane}_{read}.log",
    threads: 1
    wrapper:
        "v1.28.0/bio/fastqc"


rule multiqc:
    input:
        expand(
            rules.fastqc.output,
            zip,
            individual=samples.individual_id,
            sample=samples.sample_id,
            lane=samples.lane_id,
            read=samples.units,
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
