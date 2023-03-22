rule get_xtea_annotation:
    output:
        gencode="resources/gencode.v42.annotation.gff3",
        rep_lib=directory("resources/rep_lib_annotation"),
        blacklist="resources/sv_blacklist.bed",
    log:
        "resources/get_xtea_annotation.log",
    conda:
        "../envs/xtea.yaml"
    shell:
        """
        touch {log} && exec > {log} 2>&1
        curl http://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_42/gencode.v42.annotation.gff3.gz | \
            gunzip -c > {output.gencode}
        mkdir -p {output.rep_lib}
        wget https://github.com/parklab/xTea/raw/master/rep_lib_annotation.tar.gz
        tar -xvf rep_lib_annotation.tar.gz -C {output.rep_lib}
        rm -f rep_lib_annotation.tar.gz
        curl https://cf.10xgenomics.com/supp/genome/GRCh38/sv_blacklist.bed > {output.blacklist}
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
                rules.sambamba_merge.output,
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
        gencode=rules.get_xtea_annotation.output.gencode,
        blacklist=rules.get_xtea_annotation.output.blacklist,
        fa=rules.gen_ref.output.fa,
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
        script="{outdir}/xtea/{platform}/{individual}/{reptype1}/run_xTEA_pipeline.sh",
        rep_lib=rules.get_xtea_annotation.output.rep_lib,
        gencode=rules.get_xtea_annotation.output.gencode,
        blacklist=rules.get_xtea_annotation.output.blacklist,
        fa=rules.gen_ref.output.fa,
    output:
        "{outdir}/xtea/{platform}/{individual}/{reptype1}/{individual}.aln.sorted_{reptype2}.vcf",
    threads: 8
    conda:
        "../envs/xtea.yaml"
    log:
        "{outdir}/xtea/{platform}/{individual}/{reptype1}/run_xtea_{reptype2}.log",
    shell:
        """
        touch {log} && exec > {log} 2>&1

        # fix the run_xTEA_pipeline.sh script
        sed -i 's/--bamsnap //g' {input.script}

        # run xtea
        bash {input.script}
        """
