---
title: 'VPsearch: fast exact sequence similarity search for genomic sequences'
tags:
  - python
  - genomics
  - bioinformatics
authors:
  - name: Joris Vankerschaver
    orcid: 0000-0002-5813-5659
    affiliation: "1, 2"
  - name: Steven J. Kern
    orcid: 0000-0002-3789-7400
    affiliation: 3
  - name: Robert Kern
    affiliation: 3
affiliations:
 - name: Center for Biosystems and Biotech Data Analysis, Ghent University Global Campus, Republic of Korea
   index: 1
 - name: Department of Applied Mathematics, Computer Science and Statistics, Ghent University, Belgium
   index: 2
 - name: Enthought Inc., 200 W Cesar Chavez, Austin, TX 78701, United States
   index: 3
date: 1 January 2022
bibliography: paper.bib

---

# Summary

Similarity search is a central task in computational biology, and in genomics
in particular. In genomics, similarity search usually takes the following form:
given an unknown nucleotide or protein sequence (the query), what are the most
similar sequences in a given database of known sequences? In this context,
similarity search is important for taxonomic determination, to establish
phylogenetic relationships, or to annotate sequences and genes with functional
information. With the advent of easily accessible high-throughput sequencing
technologies, the amount of available genomic data continues to grow rapidly,
and the demands for computationally efficient and accurate similarity search
implementations have increased accordingly.

Over the years, a number of tools for similarity search have improved upon the
venerable BLAST [@1990-blast] in terms of lookup speed and accuracy. Some of
these, such as the FASTA tool suite [@2016-pearson-FindingProteinNucleotide],
provide rapid protein or nucleotide similarity search based on sequence content
alone. Others, such as the RDP classifier [@2007-wang-NaiveBayesianClassifier]
for microbiome analysis, take taxonomic information or other domain-specific
information into account to improve classification sensitivity or to provide
additional confidence measures. For whole-genome sequences, data structures for
approximate similarity search have been adopted to improve sequence lookup
speed [@2019-marcais-SketchingSublinearData].

# Statement of need

VPsearch is a light-weight Python package and command-line tool to perform
similarity search. Unlike some of the approximate tools mentioned in the
introduction, VPsearch provides an exact similarity search implementation,
taking the full sequence content into account (rather than a $k$-mer spectrum
or other approximation).

Given a database of known sequences, VPsearch builds a so-called _vantage point
tree_ [@1991-uhlmann-SatisfyingGeneralProximity;
@1993-yianilos-DataStructuresAlgorithms], a data structure that allows for
similarity lookups in time proportional to the logarithm of the size of the
database. For a set of unknown sequences, VPsearch is then able to query this
tree and return the best matching results from the database. In the case study
below we show that for short sequences (such as the 16S rRNA gene used in
bacterial classification) VPsearch outperforms both BLAST (7x speedup) and
ggsearch36 from the FASTA suite (27x speedup) without any loss in accuracy.

The VPsearch tool is implemented in Python, using Cython [@2011-behnel-cython]
for performance-critical sections, and to interface with external libraries. To
compare sequences during indexing and querying, VPsearch calls out to Parasail
[@2016-daily-ParasailSIMDLibrary], a library of SIMD-optimized implementations
for global and local sequence alignment.

VPsearch outputs similarity search results in the "BLAST-6" tabular format also
used by BLAST [@1990-blast], Diamond
[@2021-buchfink-SensitiveProteinAlignments], the FASTA tool suite
[@2016-pearson-FindingProteinNucleotide], and others, so that it can be used
as a drop-in replacement for any of these tools. VPsearch is able to return the
$k$ most similar sequences for a given query, not just the most similar match,
and supports querying the database in multithreaded mode.

# Case study

We compare the performance of VPsearch with two standard tools for sequence
lookup: Blast+, as a standard tool that is optimized for inexact but fast
sequence lookup via the matching sequence pair heuristic, and ggsearch36, part
of the FASTA suite, which relies on exact alignment to achieve higher accuracy
at the cost of greatly increased lookup times. We show that VPsearch manages to
combine the good aspects of both tools, while avoiding the drawbacks.

![Sequence lookup time for 232 sequences as a function of the size of the
    database. For small databases (less than 10,000 sequences), VPsearch
    performs comparably to Blast+ and ggsearch36. For realistic databases
    (consisting of more than 50,000 sequences), the VPsearch lookup times
    scales logarithmically as the size of the database
    increases.\label{fig:execution-time}](execution-time.pdf){ width=70% }

We use VPsearch to look up 232 query sequences from the Mothur SOP dataset
[@2013-kozich-DevelopmentDualIndexSequencing] in the Silva database of
bacterial 16S sequences [@2013-quast-SILVARibosomalRNA]. The database was
processed by excising the v4 region of the full-length 16S sequences and
removing duplicate sequences, resulting in a database of 230,013 sequences
(each approximately 250 base pairs in length) with known taxonomies. The Mothur
SOP dataset was processed using the dada2 protocol
[@2016-callahan-DADA2HighresolutionSample], resulting in 232 Amplicon Sequence
Variants (ASVs), representing distinct taxonomic units in the dataset.

On the full Silva database, VPsearch is clearly the fastest (20s total lookup
time), compared to Blast+ (157s) and ggsearch (561.3s)
(\autoref{fig:execution-time}). For Blast+ and ggsearch36, the total lookup
time scales linearly with the size of the database, whereas for VPsearch the
scaling is logarithmical (in other words, making the database 10 times larger
adds a constant factor to the total lookup time).

For each lookup, we compared the top matches (ranked by alignment score)
between VPsearch, ggsearch36, and Blast+. Out of 232 ASVs there is one sequence
where the taxonomic assignment differs between ggsearch36 and VPsearch, due to
a small difference in how the alignment parameters are chosen for both
algorithms. Both algorithms identify the ASV as being in the family of
_Lachnospiraceae_, with the difference on the genus level. Between VPsearch and
Blast+, there are three different assignments, due to the fact that several
sequences in the database present an equally plausible match for the query
sequence.

# Acknowledgements

We would like to thank Peter Zahemszky, for fixing a bug in the computation of
the score for sequences with ambiguous nucleotides, as well as Jun Isayama and
Yuko Kiridoshi for stimulating discussions, and Homin Park for help in setting
up the computational infrastructure that was used for the case study.

# References
