
params.gatk = [:]
params.gatk.ram = 4
params.gatk.jar = ""

process mutect_matched {
	 tag "${meta.sampleName}"

	input:
	tuple val(meta), path (bam_normal), path (bam_tumor)

	output:
	tuple val(meta), path("${meta.sampleName}.m2.matched.vcf"), emit: results

	script:
	"""#!/usr/bin/env bash

	java -Xmx${params.gatk.ram}G -jar ${params.gatk.jar} Mutect2 \
	--native-pair-hmm-threads 4 \
	--reference genome \
	--input ${bam_normal} \
	--input ${bam_tumor} \
	--normal-sample Normal --tumor-sample Tumor \
	--f1r2-tar-gz ${meta.sampleName}.matched.m2.f1r2.tar.gz \
	--output ${meta.sampleName}.matched.m2.vcf \
	-bamout ${meta.sampleName}.matched.m2.bam \
	--assembly-region-out ${meta.sampleName}.matched.m2.assembly.txt \
	2> ${meta.sampleName}.matched.log \
	> ${meta.sampleName}.matched.out
	"""
}
