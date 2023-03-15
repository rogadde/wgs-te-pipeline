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
            (wc.sample, "illumina"), ["r1", "r2"]
        ].values.flatten(),
    output:
        "{outdir}/align/illumina/{sample}.aln.bam",
    threads: 32
    shell:
        """
        prefix="$(dirname {output})/$(basename {output} .aln.bam)"
        idxbase="$(dirname {input.idx[0]})/$(basename {input.idx[0]} .amb)"

        {input.bwakit}/run-bwamem \
            -R "@RG\\tID:{wildcards.sample}\\tSM:{wildcards.sample}\\tPL:ILLUMINA" \
            -d \
            -t {threads} \
            -o $prefix \
            $idxbase \
            {input.reads} | bash
        """


rule sambamba_sort:
    input:
        "{outdir}/align/{platform}/{sample}.aln.bam",
    output:
        "{outdir}/align/{platform}/{sample}.aln.sorted.bam",
    log:
        "{outdir}/align/{platform}/{sample}_sort.log",
    params:
        extra="",  # this must be preset
    threads: 8
    wrapper:
        "v1.23.5/bio/sambamba/sort"


rule sambamba_index:
    input:
        rules.sambamba_sort.output,
    output:
        "{outdir}/align/{platform}/{sample}.aln.sorted.bam.bai",
    log:
        "{outdir}/align/{platform}/{sample}_index.log",
    params:
        extra="",  # this must be preset
    threads: 8
    wrapper:
        "v1.23.5/bio/sambamba/index"
