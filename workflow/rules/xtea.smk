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


# TODO: add blacklist file
rule prepare_xtea:
    input:
        rep_lib=rules.get_xtea_annotation.output.rep_lib,
        gencode=rules.get_xtea_annotation.output.gencode,
        blacklist=rules.get_xtea_annotation.output.blacklist,
        fa=rules.gen_ref.output.fa,
        bam=rules.sambamba_sort.output,
        bai=rules.sambamba_index.output,
    output:
        expand(
            "{outdir}/xtea/{sample}/{reptype}/run_xTEA_pipeline.sh",
            reptype=config["reptype"],
            allow_missing=True,
        ),
    conda:
        "../envs/xtea.yaml"
    script:
        "../scripts/xtea.py"


rule run_xtea:
    input:
        script="{outdir}/xtea/{sample}/{reptype1}/run_xTEA_pipeline.sh",
        rep_lib=rules.get_xtea_annotation.output.rep_lib,
        gencode=rules.get_xtea_annotation.output.gencode,
        blacklist=rules.get_xtea_annotation.output.blacklist,
        fa=rules.gen_ref.output.fa,
        bam=rules.sambamba_sort.output,
        bai=rules.sambamba_index.output,
    output:
        "{outdir}/xtea/{sample}/{reptype1}/{sample}.aln.sorted_{reptype2}.vcf",
    conda:
        "../envs/xtea.yaml"
    log:
        "{outdir}/xtea/{sample}/{reptype1}/run_xtea_{reptype2}.log",
    shell:
        """
        touch {log} && exec > {log} 2>&1

        # fix the run_xTEA_pipeline.sh script
        sed -i 's/--bamsnap //g' {input.script}

        # run xtea
        # cd {wildcards.outdir}/xtea
        # bash $(pwd)/{wildcards.sample}/{wildcards.reptype1}/run_xTEA_pipeline.sh
        bash {input.script}
        """
