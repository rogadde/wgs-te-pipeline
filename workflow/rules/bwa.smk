rule bwa_index:
    input:
        bwakit=rules.install_bwakit.output,
        fa=rules.gen_ref.output[0],
    output:
        idx=multiext(
            f"resources/hs38d1{region_name}.fa",
            ".amb",
            ".ann",
            ".bwt",
            ".pac",
            ".sa",
        ),
    log:
        "resources/bwa_index.log",
    shell:
        "{input.bwakit}/bwa index {input.fa} > {log} 2>&1"


def get_fastq(wildcards):
    r1 = samples.loc[
        (wildcards.individual, "illumina", wildcards.sample, wildcards.lane), "r1"
    ]
    r2 = samples.loc[
        (wildcards.individual, "illumina", wildcards.sample, wildcards.lane), "r2"
    ]
    return {"r1": r1, "r2": r2}


rule bwa_mem:
    input:
        unpack(get_fastq),
        bwakit=rules.install_bwakit.output,
        idx=rules.bwa_index.output.idx,
        fa=rules.gen_ref.output[0],
    output:
        "{outdir}/align/illumina/{individual}/{sample}_L00{lane}.aln.bam",
    threads: 32
    shell:
        """
        prefix="$(dirname {output})/$(basename {output} .aln.bam)"
        idxbase="$(dirname {input.idx[0]})/$(basename {input.idx[0]} .amb)"

        {input.bwakit}/run-bwamem \
            -R "@RG\\tID:{wildcards.individual}\\tSM:{wildcards.sample}\\tPL:ILLUMINA" \
            -d \
            -t {threads} \
            -o $prefix \
            $idxbase \
            {input.r1} {input.r2} | bash
        """


rule sambamba_sort:
    input:
        rules.bwa_mem.output,
    output:
        "{outdir}/align/illumina/{individual}/{sample}_L00{lane}.aln.sorted.bam",
    log:
        "{outdir}/align/illumina/{individual}/{sample}_L00{lane}_sort.log",
    params:
        extra="",  # this must be present for the wrapper to work
    threads: 8
    wrapper:
        "v1.23.5/bio/sambamba/sort"


def get_lanes(wildcards):
    my_lanes = samples.loc[
        (wildcards.individual, "illumina", wildcards.sample), "lane_id"
    ]
    bams = expand(
        rules.sambamba_sort.output,
        lane=my_lanes,
        allow_missing=True,
    )
    return bams


rule sambamba_merge:
    input:
        get_lanes,
    output:
        "{outdir}/align/illumina/{individual}/{sample}.aln.sorted.bam",
    log:
        "{outdir}/align/illumina/{individual}/{sample}_merge.log",
    params:
        extra="",  # this must be present for the wrapper to work
    threads: 8
    wrapper:
        "v1.24.0/bio/sambamba/merge"


rule sambamba_index:
    input:
        rules.sambamba_merge.output,
    output:
        rules.sambamba_merge.output[0] + ".bai",
    log:
        rules.sambamba_merge.output[0].replace("sort", "index"),
    params:
        extra="",  # this must be present for the wrapper to work
    threads: 8
    wrapper:
        "v1.23.5/bio/sambamba/index"
