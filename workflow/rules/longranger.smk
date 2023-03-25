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
        fastqs=lambda wc: samples.loc[
            (wc.individual, "10x", wc.sample), ["r1", "r2"]
        ].values.flatten(),
        ref=rules.longranger_mkref.output,
    output:
        bam="{outdir}/align/10x/{individual}/{sample}/outs/possorted_bam.bam",
        bai="{outdir}/align/10x/{individual}/{sample}/outs/possorted_bam.bam.bai",
    threads: 32
    script:
        "../scripts/longranger_align.py"


rule rule_install_barcodemate:
    output:
        directory("resources/BarcodeMate"),
    shell:
        """
        cd resources
        git clone https://github.com/simoncchu/BarcodeMate
        """


rule barcodemate:
    input:
        barcodemate=rules.rule_install_barcodemate.output,
        bam=rules.longranger_align.output.bam,
        bai=rules.longranger_align.output.bai,
    output:
        bam=rules.longranger_align.output.bam.replace("bam", "barcodemate.bam"),
    conda:
        "../envs/barcodemate.yaml"
    log:
        rules.longranger_align.output.bam.replace("bam", "barcodemate.log"),
    threads: 32
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
