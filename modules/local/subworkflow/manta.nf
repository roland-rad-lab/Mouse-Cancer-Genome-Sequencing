#!/usr/bin/env nextflow

include { interval_bed } from "../software/genome/main"
include { manta_matched; manta_matched_post } from "../software/manta/main"

workflow MANTA
{
	take:
		ch_fasta
		ch_dict
		ch_interval
		ch_data

	main:
		ch_interval_list = ch_interval.collectFile (name: 'interval_names.tsv', newLine: true)
		interval_bed (ch_dict, ch_interval_list)

		ch_data_expanded = ch_data.map { it ->
			tuple ( it, it["normalBAM"], it["normalBAI"], it["tumorBAM"], it["tumorBAI"] )
		}

		manta_matched (ch_fasta, interval_bed.out.result, ch_data_expanded)
		manta_matched_post (manta_matched.out.sv)

	emit:
		result = manta_matched_post.out.result
		indel = manta_matched.out.indel
}
