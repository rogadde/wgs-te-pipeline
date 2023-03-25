# handle specified region
region = (
    "".join(config["genome"]["region"])
    if isinstance(config["genome"]["region"], list)
    else config["genome"]["region"]
)
region_name = f"_{region}" if region != "all" else ""
genome_name = config["genome"]["name"] + region_name


rule get_genome:
    input:
        fa=FTP.remote(
            config["genome"]["ftp"],
            keep_local=True,
            static=True,
            immediate_close=True,
        ),
    output:
        fa=f"resources/{genome_name}.fa",
        fai=f"resources/{genome_name}.fa.fai",
    log:
        "resources/get_genome.log",
    conda:
        "../envs/ref.yaml"
    script:
        "../scripts/get_genome.py"
