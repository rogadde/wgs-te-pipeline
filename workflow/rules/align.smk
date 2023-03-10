rule bwa_index:
    input:
        bwakit=rules.install_bwakit.output,
        fa=rules.gen_ref.output[0],
    output:
        idx=multiext(
            f"resources/hs38DH{region_name}.fa",
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
        reads=lambda wc: samples.loc[wc.sample, ["r1", "r2"]],
    output:
        "{outdir}/results/align/{sample}.aln.bam",
    threads: 4
    shell:
        """
        prefix="$(dirname {output})/$(basename {output} .aln.bam)"
        idxbase="$(dirname {input.idx[0]})/$(basename {input.idx[0]} .amb)"

        # -s sort option doesn't work
        {input.bwakit}/run-bwamem \
            -R "@RG\\tID:{wildcards.sample}\\tSM:{wildcards.sample}\\tPL:ILLUMINA" \
            -d \
            -t {threads} \
            -o $prefix \
            $idxbase \
            {input.reads} | bash
        """
