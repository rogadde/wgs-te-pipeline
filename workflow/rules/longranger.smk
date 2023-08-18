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
        fa=rules.get_genome.output.fa,
    output:
        directory(f"resources/refdata-{genome_name}/"),
    shell:
        """
        {input.longranger}/longranger mkref {input.fa}
        mv refdata-* resources/
        """


rule longranger_align:
    input:
        longranger=rules.install_longranger.output,
        fastqs=[
            "{outdir}/trimmed/10x/{individual}/{sample}_L00{lane}.1.fq.gz",
            "{outdir}/trimmed/10x/{individual}/{sample}_L00{lane}.2.fq.gz",
        ],
        ref=rules.longranger_mkref.output,
    output:
        bam="{outdir}/align/10x/{individual}/{sample}/outs/possorted_bam.bam",
        bai="{outdir}/align/10x/{individual}/{sample}/outs/possorted_bam.bam.bai",
    threads: 48
    script:
        "../scripts/longranger_align.py"


rule rule_install_barcodemate:
    output:
        directory("resources/BarcodeMate"),
    shell:
        """
        cd resources
        git clone https://github.com/mikecuoco/BarcodeMate
        """


rule barcodemate:
    input:
        barcodemate=rules.rule_install_barcodemate.output,
        bam=rules.longranger_align.output.bam,
        bai=rules.longranger_align.output.bai,
    output:
        bam=rules.longranger_align.output.bam.replace(".bam", "_barcodemate.bam"),
    conda:
        "../envs/barcodemate.yaml"
    log:
        rules.longranger_align.output.bam.replace(".bam", "_barcodemate.log"),
    threads: 48
    shell:
        """
        # make tmpdir in same directory as output to avoid cross-device link error
        tmpdir=$(mktemp -d -p $(dirname {output.bam}))

        python resources/BarcodeMate/x_toolbox.py -C \
            -b {input.bam} \
            -o {output.bam} \
            -p $tmpdir \
            -n {threads} 2> {log}

        # remove tmpdir
        rm -rf $tmpdir
        """
