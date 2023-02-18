rule install_bwakit:
    output:
        "{outdir}/resources/bwa.kit",
    conda:
        "../envs/ref.yml"
    log:
        "{outdir}/resources/install_bwakit.log",
    shell:
        """
        mkdir -p resources && cd resources
        wget -O- -q --no-config https://sourceforge.net/projects/bio-bwa/files/bwakit/bwakit-0.7.15_x64-linux.tar.bz2 | tar xfj -
        """


# handle specified region
region = (
    "".join(config["genome"]["region"])
    if isinstance(config["genome"]["region"], list)
    else config["genome"]["region"]
)
region_name = f"_{region}" if region != "all" else ""


rule gen_ref:
    input:
        rules.install_bwakit.output,
    output:
        multiext(
            f"{{outdir}}/resources/{{ref}}/{{ref}}{region_name}",
            ".fa",
            ".fa.fai",
            ".genome",
        ),
    log:
        "{outdir}/resources/{ref}/gen_ref.log",
    conda:
        "../envs/ref.yml"
    params:
        region=" ".join(config["genome"]["region"])
        if isinstance(config["genome"]["region"], list)
        else config["genome"]["region"],
    cache: True
    shell:
        """
        # start logging
        touch {log} && exec 2>{log}

        # download reference
        url38="ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/000/001/405/GCA_000001405.15_GRCh38/seqs_for_alignment_pipelines.ucsc_ids/GCA_000001405.15_GRCh38_full_analysis_set.fna.gz"

        wget -O- $url38 | gzip -dc > hs38DH.fa
        cat {input}/resource-GRCh38/hs38DH-extra.fa >> hs38DH.fa

        # filter for the region if specified
        if [ "{params.region}" != "all" ]; then
            samtools faidx {wildcards.ref}.fa {params.region} > {output[0]}
        else
            mv {wildcards.ref}.fa {output[0]}
        fi

        # index
        samtools faidx {output[0]}
        cut -f 1,2 {output[1]} > {output[2]}
        """
