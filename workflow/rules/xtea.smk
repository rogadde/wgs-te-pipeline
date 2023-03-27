rule get_xtea_annotation:
    input:
        FTP.remote(
            config["genome"]["ftp_gff"],
            keep_local=True,
            static=True,
            immediate_close=True,
        ),
    output:
        genes="resources/genes.gff3",
        rep_lib=directory("resources/rep_lib_annotation"),
    log:
        "resources/get_xtea_annotation.log",
    conda:
        "../envs/xtea.yaml"
    shell:
        """
        touch {log} && exec > {log} 2>&1

        # get the genes
        gunzip -c {input} > {output.genes}

        # get the replib
        mkdir -p {output.rep_lib}
        wget https://github.com/parklab/xTea/raw/master/rep_lib_annotation.tar.gz
        tar -xvf rep_lib_annotation.tar.gz -C {output.rep_lib}
        rm -f rep_lib_annotation.tar.gz
        """


# get bam files for this individual for each platform
def get_bam(wildcards):
    i = dict()
    my_samples = samples.loc[samples["individual_id"] == wildcards.individual, :]
    if "illumina" in wildcards.platform:
        my_platform_samples = set(
            my_samples.loc[my_samples["platform"] == "illumina", "sample_id"]
        )
        d = {
            "illumina_bam": expand(
                rules.sambamba_sort.output,
                sample=my_platform_samples,
                allow_missing=True,
            ),
            "illumina_bai": expand(
                rules.sambamba_index.output,
                sample=my_platform_samples,
                allow_missing=True,
            ),
        }
        i.update(d.copy())
    if "10x" in wildcards.platform:
        my_platform_samples = set(
            my_samples.loc[my_samples["platform"] == "10x", "sample_id"]
        )
        d = {
            "10x_bam": expand(
                rules.longranger_align.output.bam,
                sample=my_platform_samples,
                allow_missing=True,
            ),
            "10x_bx_bam": expand(
                rules.barcodemate.output.bam,
                sample=my_platform_samples,
                allow_missing=True,
            ),
        }
        i.update(d.copy())

    if not i:
        raise ValueError(
            "No bam files found for individual {wildcards.individual} and platform {wildcards.platform}"
        )

    return i


rule prepare_xtea:
    input:
        unpack(get_bam),
        rep_lib=rules.get_xtea_annotation.output.rep_lib,
        gencode=rules.get_xtea_annotation.output.genes,
        fa=rules.get_genome.output.fa,
    output:
        script=expand(
            "{outdir}/xtea/{platform}/{individual}/{reptype}/run_xTEA_pipeline.sh",
            reptype=config["reptype"],
            allow_missing=True,
        ),
    threads: 8
    conda:
        "../envs/xtea.yaml"
    script:
        "../scripts/xtea.py"


rule run_xtea:
    input:
        unpack(get_bam),
        script="{outdir}/xtea/{platform}/{individual}/{reptype}/run_xTEA_pipeline.sh",
        rep_lib=rules.get_xtea_annotation.output.rep_lib,
        genes=rules.get_xtea_annotation.output.genes,
        fa=rules.get_genome.output.fa,
    output:
        "{outdir}/xtea/{platform}/{individual}/{reptype}.vcf",
    threads: 8
    conda:
        "../envs/xtea.yaml"
    log:
        "{outdir}/xtea/{platform}/{individual}/{reptype}.log",
    shell:
        """
        touch {log} && exec > {log} 2>&1

        # fix the run_xTEA_pipeline.sh script
        sed -i 's/--bamsnap //g' {input.script}

        # run xtea
        bash {input.script}

        # move the vcf file to the expected location
        mv {wildcards.outdir}/xtea/{wildcards.platform}/{wildcards.individual}/{wildcards.reptype}/*vcf \
            {wildcards.outdir}/xtea/{wildcards.platform}/{wildcards.individual}/{wildcards.reptype}.vcf
        """
