from snakemake.remote import FTP

FTP = FTP.RemoteProvider()


rule install_bwakit:
    output:
        directory("resources/bwa.kit"),
    conda:
        "../envs/ref.yml"
    log:
        "resources/install_bwakit.log",
    shell:
        """
        mkdir -p resources && cd resources
        wget -O- -q --no-config https://sourceforge.net/projects/bio-bwa/files/bwakit/bwakit-0.7.15_x64-linux.tar.bz2 | tar xfj -
        """


# handle specified region
region = (
    "".join(config["region"])
    if isinstance(config["region"], list)
    else config["region"]
)
region_name = f"_{region}" if region != "all" else ""


# generate hg38 reference with decoy and alt contigs
rule gen_ref:
    input:
        fa=FTP.remote(
            "ftp.1000genomes.ebi.ac.uk/vol1/ftp/technical/reference/GRCh38_reference_genome/GRCh38_full_analysis_set_plus_decoy_hla.fa",
            keep_local=True,
            static=True,
        ),
    output:
        multiext(
            f"resources/hs38DH{region_name}",
            ".fa",
            ".fa.fai",
        ),
    log:
        "resources/gen_ref.log",
    conda:
        "../envs/ref.yml"
    params:
        region=" ".join(config["region"])
        if isinstance(config["region"], list)
        else config["region"],
    shadow:
        "shallow"
    shell:
        """
        # start logging
        touch {log} && exec 2>{log}

        # filter for the region if specified
        if [ "{params.region}" != "all" ]; then
            samtools faidx {input} {params.region} > {output[0]}
            rm -f {input}
        else
            mv {input} {output[0]}
        fi

        # index
        samtools faidx {output[0]}
        """
