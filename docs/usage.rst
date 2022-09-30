=====
Usage
=====

Given a sequence database (in FASTA format), ``vpsearch build`` constructs an
optimized vantage point search tree. Building the tree is a one-time operation
and doesn't have to be done again unless the database changes. As an
illustration, we build a vantage point tree for a database of sequences
obtained by trimming the GTDB 16S database to the v3-v4 hypervariable
region. This database contains 10875 unique sequences, and can be found (in
compressed form) in the ``data/`` directory inside this repository::

    $ vpsearch build bac120_ssu_reps_r207-sliced-dedup.fa.gz
    Building for 10875 sequences...done.
    Linearizing...done.
    Database created in bac120_ssu_reps_r207-sliced-dedup.fa.db

As this is a relatively small database, the process finishes quickly, in about
10 seconds. For larger databases, such as the RDP database of full length
sequences, this may take longer. For example, building an index for the RDP
database takes about 20 minutes on a standard machine.

Once a tree has been built, unknown sequences can be looked up using the
``vpsearch query`` command. Here we supply a query file with a single
sequence. The ``query.fa`` file can also be found in the ``data/`` directory and
represents a *Lactobacillus helsingborgensis* sample whose sequence was
downloaded from RefSeq. We see that we have a perfect match with
``RS_GCF_000970855.1``, which happens to be the same sequence. Other matches are
highly similar but not identical, and represent different species of
*Lactobacillus* (*kimbladii*, *melliventris*, and *panisapium*, respectively)::

    $ vpsearch query bac120_ssu_reps_r207-sliced-dedup.fa.db query.fa
    NR_126253.1     RS_GCF_000970855.1      100.00  253     0       0       1       253     1       253     0       1265
    NR_126253.1     RS_GCF_014323605.1      98.81   253     0       0       1       253     1       253     0       1238
    NR_126253.1     RS_GCF_013346935.1      98.02   253     0       0       1       253     1       253     0       1220
    NR_126253.1     RS_GCF_002916935.1      97.63   253     0       0       1       253     1       253     0       1211

By default, the ``vpsearch query`` command outputs the best four matches in the
database per query sequence (the number of matches can be changed with the ``-k``
parameter). Lookup is done one query sequence at a time, but multiple queries
can be considered in parallel by enabling multiple threads; use the ``-j`` option
to specify the number of threads.

The ``vpsearch query`` command attempts to output its results in the standard
BLAST tabular format. The interpretation of the columns is as follows:

+------------------+--------------------+------------------------------------+
| Column name      | Example            | Notes                              |
+==================+====================+====================================+
| query ID         | NR_126253.1        |                                    |
+------------------+--------------------+------------------------------------+
| subject ID       | RS_GCF_014323605.1 |                                    |
+------------------+--------------------+------------------------------------+
| % identity       | 98.81              |                                    |
+------------------+--------------------+------------------------------------+
| alignment length | 253                |                                    |
+------------------+--------------------+------------------------------------+
| mismatches       | 0                  | currently not implemented          |
+------------------+--------------------+------------------------------------+
| gap openings     | 0                  | currently not implemented          |
+------------------+--------------------+------------------------------------+
| query start      | 1                  |                                    |
+------------------+--------------------+------------------------------------+
| query end        | 253                |                                    |
+------------------+--------------------+------------------------------------+
| subject start    | 1                  |                                    |
+------------------+--------------------+------------------------------------+
| subject end      | 253                |                                    |
+------------------+--------------------+------------------------------------+
| E-value          | 0                  | N/A (always 0)                     |
+------------------+--------------------+------------------------------------+
| bit score        | 1238               | interpreted as the alignment score |
+------------------+--------------------+------------------------------------+

Note that the number of mismatches and gap openings are currently not displayed
in the result output. This will be addressed in a future version of the
package.
