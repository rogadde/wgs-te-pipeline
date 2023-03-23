# index genome
rule bwa_mem2_index:
    input:
        rules.gen_ref.output[0],
    output:
        rules.gen_ref.output[0] + ".0123",
        rules.gen_ref.output[0] + ".amb",
        rules.gen_ref.output[0] + ".ann",
        rules.gen_ref.output[0] + ".bwt.2bit.64",
        rules.gen_ref.output[0] + ".pac",
    log:
        "resources/bwa_index.log",
    wrapper:
        "v1.24.0/bio/bwa-mem2/index"


def get_fastq(wildcards):
    return samples.loc[
        (wildcards.individual, "illumina", wildcards.sample, wildcards.lane),
        ["r1", "r2"],
    ]


# map reads
rule bwa_mem2_mem:
    input:
        reads=get_fastq,
        idx=rules.bwa_mem2_index.output,
    output:
        "{outdir}/align/illumina/{individual}/{sample}_L00{lane}.bam",
    log:
        "{outdir}/align/illumina/{individual}/{sample}_L00{lane}.bwamem2.log",
    params:
        extra=r"-R '@RG\tID:{individual}\tSM:{sample}'",
        sort="none",  # Can be 'none', 'samtools' or 'picard'.
        sort_order="queryname",  # Can be 'coordinate' (default) or 'queryname'.
        sort_extra="",  # Extra args for samtools/picard.
    threads: 32
    wrapper:
        "v1.24.0/bio/bwa-mem2/mem"


def get_lanes(wildcards):
    my_lanes = samples.loc[
        (wildcards.individual, "illumina", wildcards.sample), "lane_id"
    ]
    bams = expand(
        rules.bwa_mem2_mem.output,
        lane=my_lanes,
        allow_missing=True,
    )
    return bams


# merge lanes
rule sambamba_merge:
    input:
        get_lanes,
    output:
        "{outdir}/align/illumina/{individual}/{sample}.bam",
    log:
        "{outdir}/align/illumina/{individual}/{sample}_merge.log",
    params:
        extra="",  # this must be present for the wrapper to work
    threads: 8
    wrapper:
        "v1.24.0/bio/sambamba/merge"


# mark duplicates
def get_markdup_input(wildcards):
    if get_lanes(wildcards) > 1:
        return rules.sambamba_merge.output
    else:
        return rules.bwa_mem2_mem.output


rule samblaster_markdup:
    input:
        get_markdup_input,
    output:
        "{outdir}/align/illumina/{individual}/{sample}.mardkup.bam",
    log:
        "{outdir}/align/illumina/{individual}/{sample}_mardkup.log",
    conda:
        "../envs/samblaster.yaml"
    shell:
        "samblaster {input} {output} 2> {log}"


# coordinate sort bam
rule sambamba_sort:
    input:
        rules.samblaster_markdup.output,
    output:
        rules.samblaster_markdup.output[0].replace("markdup.bam", "markdup.sorted.bam"),
    log:
        rules.samblaster_markdup.log[0].replace("markdup", "sort"),
    params:
        extra="",  # this must be present for the wrapper to work
    threads: 8
    wrapper:
        "v1.23.5/bio/sambamba/sort"


# index bam
rule sambamba_index:
    input:
        rules.sambamba_sort.output,
    output:
        rules.sambamba_sort.output[0] + ".bai",
    log:
        rules.sambamba_sort.log[0].replace("sort", "index"),
    params:
        extra="",  # this must be present for the wrapper to work
    threads: 8
    wrapper:
        "v1.23.5/bio/sambamba/index"
