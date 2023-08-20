rule megane_build_kmerset:
    input:
        fa=rules.get_genome.output.fa,
    output:
        f"resources/megane_kmer_set/{genome_name}.fa.mk",
    log:
        f"resources/{genome_name}_megane_build_kmerset.log",
    container:
        "docker://shoheikojima/megane:v1.0.0.beta"
    shell:
        """
        outdir=$(dirname {output})
        build_kmerset -fa {input.fa} -outdir $outdir > {log} 2>&1
        """


rule megane:
    input:
        bam=rules.sambamba_sort.output,
        bai=rules.sambamba_index.output,
        mk=rules.megane_build_kmerset.output,
        fa=rules.get_genome.output.fa,
    output:
        directory("{outdir}/megane/{individual}/{sample}"),
    log:
        "{outdir}/megane/{individual}/{sample}/{sample}.log",
    container:
        "docker://shoheikojima/megane:v1.0.0.beta"
    threads: 2
    shell:
        """
        call_genotype_38 -i {input.bam} -fa {input.fa} -mk {input.mk} -outdir {output} -sample_name {wildcards.sample} -p {threads} > {log} 2>&1
        """
