//mainf.nf
reads = file(params.reads)
pair1 = file(params.pair1)
pair2 = file(params.pair2)
genome = file(params.genome)


reads1 = Channel
    .fromPath( pair1 )
    .map { path -> [ path.toString().replace("_R1", "_RX"), path ] }
reads2 = Channel
    .fromPath( pair2 )
    .map { path -> [ path.toString().replace("_R2", "_RX"), path ] }
    
// Join pairs on their key.
read_pairs = reads1
        .phase(reads2)
        .map { pair1, pair2 -> [ pathToDatasetID(pair1[1]), pair1[1], pair2[1] ] }

// Get the genome file.
genome_file = file(params.genome)


process fastqc {

    publishDir "results", mode: 'copy'

    input:
    file(reads) from reads

    output:
    file "*_fastqc.{zip,html}" into fastqc_results

    script:
    """
    fastqc $reads
    """
}

process mapping {
    echo true
    module 'bwa/0.7.2'

    input:
    set dataset_id, file(read1), file(read2) from read_pairs

    output:
    set dataset_id, file('alignment.bam') into bam_files

    """
    bwa mem -t 4 ${genome_file} ${read1} ${read2} | samtools view -Sb - | samtools sort - alignment
    """
}
