rule install_longranger:
    output:
        directory("resources/longranger-2.2.2"),
    params:
        url=config["longranger_url"],
    shell:
        """
        curl "{params.url}" > resources/longranger.tar.gz
        tar xf resources/longranger.tar.gz -C resources
        rm -f resources/longranger.tar.gz
        """


rule longranger_mkref:
    input:
        longranger=rules.install_longranger.output,
        fa=rules.gen_ref.output.fa,
    output:
        directory(f"resources/refdata-hs38d1{region_name}/"),
    shell:
        """
        {input.longranger}/longranger mkref {input.fa}
        mv refdata-hs38d1* resources/
        """


rule longranger_align:
    input:
        longranger=rules.install_longranger.output,
        fastqs=lambda wc: samples.loc[(wc.sample, "10x"), ["r1", "r2"]].values.flatten(),
        ref=rules.longranger_mkref.output,
    output:
        "{outdir}/align/10x/{sample}.aln.bam",
    threads: 32
    script:
        "../scripts/longranger_align.py"
