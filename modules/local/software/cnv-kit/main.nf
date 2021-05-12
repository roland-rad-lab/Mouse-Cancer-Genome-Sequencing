




process cnv_kit_matched {
	tag "${meta.sampleName}"


	input:
		val (reference)
		val (reference_flat)
		tuple path (interval_bed), path (interval_bed_index)
		tuple val (meta), path (bam_normal), path (bai_normal), path (bam_tumor), path (bai_tumor)

	script:
	"""#!/usr/bin/env bash
source ${params.script_base}/file_handling.sh
temp_file_b=\$(moc_mktemp_file .)
trap "rm \${temp_file_b}" EXIT

extract_if_zip ${interval_bed} interval_bed_extracted \${temp_file_b}
mkdir -p CNVKit/matched
cnvkit.py batch \\
	${bam_tumor} \\
	--normal ${bam_normal} \\
	--fasta ${reference} \\
	--output-reference Reference.matched.cnn \\
	--output-dir CNVKit/matched/ \\
	--short-names \\
	--diagram \\
	--scatter \\
	--annotate ${reference_flat} \\
	--access "" \\
	--targets \${interval_bed_extracted} \\
	--drop-low-coverage \\
	-m wgs \\
	-p ${params.cnv_kit.threads}

for stype in Normal Tumor;
do
	for file in \$(find CNVKit/matched/ -type f -name "*\${stype}*");
	do
		file_new=\$(echo \${file} | sed -e "s/\${stype}/matched.\${stype}/")
		echo "Rename '\${file}' to '\${file_new}'"
		mv \${file} \${file_new}
	done
done
	"""

}

process cnv_kit_single {
	tag "${meta.sampleName}"

	input:
		val (reference)
		val (reference_flat)
		tuple path (interval_bed), path (interval_bed_index)
		tuple val (meta), val (type), path (bam), path (bai)

	script:
	"""#!/usr/bin/env bash
source ${params.script_base}/file_handling.sh
temp_file_b=\$(moc_mktemp_file .)
trap "rm \${temp_file_b}" EXIT

extract_if_zip ${interval_bed} interval_bed_extracted \${temp_file_b}
mkdir -p CNVKit/matched
cnvkit.py batch \\
	${bam} \\
	--normal \\
	--fasta ${reference} \\
	--output-reference Reference.${type}.cnn \\
	--output-dir CNVKit/single/ \\
	--short-names \\
	--diagram \\
	--scatter \\
	--annotate ${reference_flat} \\
	--access "" \\
	--targets \${interval_bed_extracted} \\
	--drop-low-coverage \\
	-m wgs \\
	-p ${params.cnv_kit.threads}

	"""
}

