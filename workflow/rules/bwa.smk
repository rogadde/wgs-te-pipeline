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


rule bwa_mem:
    input:
        bwakit=rules.install_bwakit.output,
        idx=rules.bwa_index.output.idx,
        fa=rules.gen_ref.output[0],
        reads=lambda wc: samples.loc[
            (wc.individual, wc.sample, "illumina"), ["r1", "r2"]
        ].values.flatten(),
    output:
        "{outdir}/align/illumina/{individual}/{sample}.aln.bam",
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
            {input.reads} | bash
        """


rule sambamba_sort:
    input:
        rules.bwa_mem.output,
    output:
        "{outdir}/align/illumina/{individual}/{sample}.aln.sorted.bam",
    log:
        "{outdir}/align/illumina/{individual}/{sample}_sort.log",
    params:
        extra="",  # this must be present for the wrapper to work
    threads: 8
    wrapper:
        "v1.23.5/bio/sambamba/sort"


rule sambamba_index:
    input:
        rules.sambamba_sort.output,
    output:
        rules.sambamba_sort.output[0] + ".bai",
    log:
        rules.sambamba_sort.output[0].replace("sort", "index"),
    params:
        extra="",  # this must be present for the wrapper to work
    threads: 8
    wrapper:
        "v1.23.5/bio/sambamba/index"
