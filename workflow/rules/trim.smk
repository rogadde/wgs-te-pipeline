rule trimmomatic_se:
    input:
        r1=lambda wc: get_fastq(wc, "r1"),
    output:
        r1="{outdir}/trimmed/{platform}/{individual}/{sample}_L00{lane}.fq.gz",
    log:
        "{outdir}/trimmed/{platform}/{individual}/{sample}_L00{lane}.log",
    params:
        # list of trimmers (see manual)
        trimmer=["ILLUMINACLIP:TruSeq3-SE.fa:2:30:10", "TRAILING:3"],
        # optional parameters
        extra="-phred33",
        compression_level="-9",
    wrapper:
        "v2.1.1/bio/trimmomatic/se"


rule trimmomatic_pe:
    input:
        r1=lambda wc: get_fastq(wc, "r1"),
        r2=lambda wc: get_fastq(wc, "r2"),
    output:
        r1=temp("{outdir}/trimmed/{platform}/{individual}/{sample}_L00{lane}.1.fq.gz"),
        r2=temp("{outdir}/trimmed/{platform}/{individual}/{sample}_L00{lane}.2.fq.gz"),
        r1_unpaired=temp(
            "{outdir}/trimmed/{platform}/{individual}/{sample}_L00{lane}.1.unpaired.fq.gz"
        ),
        r2_unpaired=temp(
            "{outdir}/trimmed/{platform}/{individual}/{sample}_L00{lane}.2.unpaired.fq.gz"
        ),
    log:
        "{outdir}/trimmed/{platform}/{individual}/{sample}_L00{lane}.log",
    params:
        # list of trimmers (see manual)
        trimmer=["ILLUMINACLIP:TruSeq3-PE.fa:2:30:10", "TRAILING:3"],
        # optional parameters
        extra="-phred33",
        compression_level="-9",
    wrapper:
        "v2.0.0/bio/trimmomatic/pe"
