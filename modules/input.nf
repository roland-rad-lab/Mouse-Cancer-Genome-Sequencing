#!/usr/bin/env nextflow

// Check file extension
def file_has_extension (it, extension)
{
	it.toString ().toLowerCase ().endsWith (extension.toLowerCase ())
}

// Return file if it exists
def file_from_path (it)
{
	if (it == null || it.isEmpty () ) exit 1, "[MoCaSeq] error: No value supplied for FASTQ or BAM input file. If using input method TSV set to NA if no file required. See '--help' flag and documentation under 'running the pipeline' for more information."
	// If glob == true file returns a list if it contains wildcard chars
	def f = file(it, glob: false)
	if (!f.exists()) exit 1, "[MoCaSeq] error: Cannot find supplied FASTQ or BAM input file. If using input method TSV set to NA if no file required. See '--help' flag and documentation under 'running the pipeline' for more information. Check file: ${it}"
	return f
}

// Check if a row has the expected number of columns
def row_check_column_n (row, number)
{
	if (row.size () != number) exit 1, "[MoCaSeq] error:  Invalid TSV input - malformed row (e.g. missing column) in ${row}, see '--help' flag and documentation under 'running the pipeline' for more information"
	return true
}

// Channelling the TSV file containing FASTQ or BAM 
def extract_data (tsv_file)
{
	Channel.fromPath (tsv_file)
		.splitCsv (header: true, sep: '\t')
		.dump (tag:'tsv_extract')
		.map { row ->
			def expected_keys = ['Sample_Name', 'Library_ID', 'Lane', 'Colour_Chemistry', 'SeqType', 'Organism', 'Type', 'R1', 'R2', 'BAM']
			if ( !row.keySet ().containsAll (expected_keys) ) exit 1, "[MoCaSeq] error: Invalid TSV input - malformed column names. Please check input TSV. Column names should be: ${expected_keys.join(", ")}"

			row_check_column_n (row, 10)

			if ( row.Sample_Name.isEmpty() ) exit 1, "[MoCaSeq] error: the Sample_Name column is empty. Ensure all cells are filled or contain 'NA' for optional fields. Check row:\n ${row}"
			if ( row.Type.isEmpty () ) exit 1, "[MoCaSeq] error: the Type column is empty. Ensure all cells are filled or contain 'NA' for optional fields. Check row:\n ${row}"
			if ( row.BAM.isEmpty() ) exit 1, "[MoCaSeq] error: the BAM column is empty. Ensure all cells are filled or contain 'NA' for optional fields. Check row:\n ${row}"

                        if ( !(row.Type == "Normal" || row.Type == "Tumor") ) exit 1, "MoCaSeq] error: Type was not [Normal|Tumor]. Check row\n ${row}"

                        def r1 = row.R1.matches('NA') ? null : file_from_path (row.R1)
                        def r2 = row.R2.matches('NA') ? null : file_from_path (row.R2)
                        def bam = row.BAM.matches('NA') ? null : file_from_path (row.BAM)

                        [
                                "sampleName": row.Sample_Name,
                                "libraryId": row.Library_ID,
                                "lane": row.Lane,
                                "colour": row.Colour_Chemistry,
                                "seqType": row.SeqType,
                                "organism": row.Organism,
                                "type": row.Type,
                                "r1": r1,
                                "r2": r2,
                                "bam": bam
                        ]	
		}.reduce ( [:] ) { accumulator, item ->
			if ( accumulator.containsKey (item["sampleName"]) )
			{
				accumulator[item["sampleName"]].add (item)
			}
			else
			{
				accumulator[item["sampleName"]] = [item]
			}
			accumulator
		}.flatMap ().map { it ->
			it.value.inject ([:]) { accumulator, item ->
				if ( accumulator.size () == 0 )
				{
					accumulator["sampleName"] = it.key
					accumulator["organism"] = item["organism"]
				}
				if ( item["type"] == "Normal")
				{
					accumulator["normalBAM"] = item["bam"]
				}
				if ( item["type"] == "Tumor" )
				{
					accumulator["tumorBAM"] = item["bam"]
				}
				accumulator
			}
		}
}
