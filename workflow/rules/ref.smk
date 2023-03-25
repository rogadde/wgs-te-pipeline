# handle specified region
region = (
    "".join(config["region"])
    if isinstance(config["region"], list)
    else config["region"]
)
region_name = f"_{region}" if region != "all" else ""


# generate hg38 reference with decoys and no alt contigs
rule gen_ref:
    input:
        FTP.remote(
            "ftp.ncbi.nlm.nih.gov/genomes/all/GCA/000/001/405/GCA_000001405.15_GRCh38/seqs_for_alignment_pipelines.ucsc_ids/GCA_000001405.15_GRCh38_no_alt_plus_hs38d1_analysis_set.fna.gz",
            keep_local=True,
            immediate_close=True,
            static=True,
        ),
    output:
        fa=f"resources/hs38d1{region_name}.fa",
        fai=f"resources/hs38d1{region_name}.fa.fai",
    log:
        "resources/gen_ref.log",
    conda:
        "../envs/ref.yaml"
    params:
        region=" ".join(config["region"])
        if isinstance(config["region"], list)
        else config["region"],
    shell:
        """
        # start logging
        touch {log} && exec 2>{log}

        # filter for the region if specified
        if [ "{params.region}" != "all" ]; then
            gunzip -f {input}
            fa=$(dirname {input})/$(basename {input} .gz)
            samtools faidx $fa {params.region} > {output.fa}
            sed -i 's/chr//g' {output.fa} # remove chrname in test, xtea doesn't like it
        else
            gunzip -c {input} > {output.fa}
        fi

        # index
        samtools faidx {output.fa}
        """
