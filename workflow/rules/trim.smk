rule trimmomatic_pe:
    input:
        r1=lambda wc: samples.loc[
            (wc.individual, wc.platform, wc.sample, wc.lane), "r1"
        ],
        r2=lambda wc: samples.loc[
            (wc.individual, wc.platform, wc.sample, wc.lane), "r2"
        ],
    output:
        r1="{outdir}/trimmed/{platform}/{individual}/{sample}_L00{lane}.1.fq.gz",
        r2="{outdir}/trimmed/{platform}/{individual}/{sample}_L00{lane}.2.fq.gz",
        r1_unpaired="{outdir}/trimmed/{platform}/{individual}/{sample}_L00{lane}.1.unpaired.fq.gz",
        r2_unpaired="{outdir}/trimmed/{platform}/{individual}/{sample}_L00{lane}.2.unpaired.fq.gz",
    log:
        "{outdir}/trimmed/{platform}/{individual}/{sample}_L00{lane}.og",
    params:
        # list of trimmers (see manual)
        trimmer=["ILLUMINACLIP:TruSeq3-PE.fa:2:30:10", "TRAILING:3"],
        # optional parameters
        extra="-phred33",
        compression_level="-9",
    wrapper:
        "v2.0.0/bio/trimmomatic/pe"