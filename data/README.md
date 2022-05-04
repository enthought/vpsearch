# Sequence data provided with vpsearch

## The query sequence

The sequence file `query.fasta` contains a single sequence, representing the
v3-v4 hypervariable region of a Lactobacillus strain. The original sequence was
downloaded from RefSeq on 28 April 2022 ([NR
126253.1](https://www.ncbi.nlm.nih.gov/nuccore/NR_126253.1)), and the
hypervariable region was excised using the ProbeMatch tool according to the
steps listed in the next section.

## The sequence database

Vpsearch will take any FASTA file of sequences, but under some circumstances it
may make sense to preprocess the sequence before building the index. This is
necessary, for example, when the sequence database consists of full-length 16S
sequences, but the query sequences come from one of the hypervariable regions
(e.g. v3-v4). In that case, it is necessary to trim and deduplicate the
sequence database to the same hypervariable region.

This directory contains a number of scripts to assist with that task of
trimming and deduplicating a FASTA file of 16S sequences. The instructions in
this file are tailored towards the use of [GTDB, version
207](https://gtdb.ecogenomic.org/), but can be adapted to handle any FASTA file
containing 16S sequences. The targeted hypervariable region is v3-v4, but this
too can be adapted.

All instructions assume that you are in the directory where this README file is
located.

### Preliminary steps

You should have the [Snakemake](https://snakemake.readthedocs.io/en/stable/)
workflow manager installed, as well as the dependencies of the workflow
(currently BioPython and RDPTools). These dependencies can be installed through
your package manager of choice, or via the provided Conda environment (see
below).

### Downloading the sequences

Download the sequence database and place it in the directory where this README
is located.

The sequence database used to demo this package is the file of bacterial 16S
sequences from GTDB, version 207, available
[here](https://data.gtdb.ecogenomic.org/releases/release207/207.0/genomic_files_reps/bac120_ssu_reps_r207.tar.gz). It
consists of 38474 full-length 16S sequences.

If your database is anything other than GTDB, version 207, edit the Snakefile
in this directory and change the variable `DATABASE` on the first line to refer
to your sequence database.

The sequence database can be in compressed or uncompressed format.

### Setting up and activating an environment (optional)

If you do not have the required workflow dependencies available in your
environment, then you can run the steps below to create a Conda environment
`primer-cutting` with the required dependencies installed.

```console
conda env create -f environment.yml
```

Once the environment has been installed, activate it via
```console
conda activate vpsearch-data
```

### Processing the sequences

At this point, processing the sequence database to obtain a sliced,
deduplicated version is only a single Snakemake command away:

```console
  snakemake -c 1
```

This should take no more than a few seconds and will produce a version of the
sequence file containing only the v3-v4 regions of the original sequences. The
filename for this reduced database will end in `-sliced-dedup.fa`; for the
version of GTDB that we use this is `bac120_ssu_reps_r207-sliced-dedup.fa`.

To target a different hypervariable region, you can supply a forward and
reverse primer (the latter as the reverse complement) in a FASTA file, and
modify the `PRIMERS` variable in the Snakefile.

The sequence file is deduplicated, and as a result it may include fewer
sequences than the original sequence file. For our version of GTDB, 10875
sequences are left as non-duplicates (out of a starting 38474).
