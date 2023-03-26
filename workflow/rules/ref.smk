rule get_genome:
    input:
        FTP.remote(
            config["genome"]["ftp"],
            keep_local=True,
            static=True,
            immediate_close=True,
        ),
    output:
        fa="resources/{}.fa".format(config["genome"]["name"]),
        fai="resources/{}.fa.fai".format(config["genome"]["name"]),
    log:
        "resources/get_genome.log",
    conda:
        "../envs/ref.yaml"
    shell:
        """
        # if zipped file, unzip
        if [[ {input} == *.gz ]]; then
            gunzip -c {input} > {output.fa}
        else
            cp {input} {output.fa}
        fi

        # index
        samtools faidx {output.fa}
        """
