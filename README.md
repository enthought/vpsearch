----------------------------------------------------------------
vpsearch - Fast Vantage-Point Tree Search for Sequence Databases
----------------------------------------------------------------

This is a package for indexing and querying a sequence database for fast
nearest-neighbor search by means of [vantage point
trees](https://en.wikipedia.org/wiki/Vantage-point_tree). For reasonably large
databases, such as [RDP](https://rdp.cme.msu.edu/), this results in sequence
lookups that are typically 5-10 times faster than other alignment-based lookup
methods.

Vantage-point tree search uses global-to-global alignment to compare sequences,
rather than seed-and-extend approximative methods as used for example by
BLAST.

## Usage

Given a sequence database (in FASTA format), `vpsearch build` constructs an
optimized vantage point search tree. Building the tree is a one-time operation
and doesn't have to be done again unless the database changes. As an
illustration, we build a vantage point tree for the RDP database of bacterial
16S sequences. This database contains 281261 sequences of which 39237 are
duplicates. After removing these duplicates, we are left with 242024 unique
sequences. Building a tree for these sequences is done with:
```bash
  $ vpsearch build rdp_download_281261seqs_dedup.fa
  Building for 242024 sequences...
  done.
  Linearizing...done.
  Database created in rdp_download_281261seqs_dedup.db
```
For the RDP database of full length sequences, this takes about 20 minutes on a
standard machine. When only selected regions of the sequences are considered,
the time needed to build a tree can be much reduced. For example, vantage point
trees for the v1-v2 hypervariable region (350 base pairs) or the v3-v4 region
(250 base pairs) of the RDP 16S sequencese can be built in 30 seconds to 1
minute.

Once a tree has been built, unknown sequences can be looked up using the
`vpsearch query` command. Here we supply a query file with a single sequence
```bash
  vpsearch query rdp_download_281261seqs_dedup.fa query.fa
  query	S000143715	99.54	1529	0	0	1	1524	1	1529	0	7546
  query	S004085923	99.08	1529	0	0	1	1524	1	1526	0	7481
  query	S004085922	99.08	1529	0	0	1	1524	1	1526	0	7481
  query	S004085925	98.50	1531	0	0	1	1524	1	1527	0	7386

```
By default, the `vpsearch query` command outputs the best four matches in the
database per query sequence (the number of matches can be changed with the `-k`
parameter). Lookup is done one query sequence at a time, but multiple queries
can be considered in parallel by enabling multiple threads; use the `-j` option
to specify the number of threads.

The `vpsearch query` command attempts to output its results in the standard
BLAST tabular format. The interpretation of the columns is as follows:

| Column name      | Example    | Notes                              |
|------------------|------------|------------------------------------|
| query ID         | query      |                                    |
| subject ID       | S000143715 |                                    |
| % identity       | 99.54      |                                    |
| alignment length | 1529       |                                    |
| mismatches       | 0          | currently not implemented          |
| gap openings     | 0          | currently not implemented          |
| query start      | 1          |                                    |
| query end        | 1524       |                                    |
| subject start    | 1          |                                    |
| subject end      | 1529       |                                    |
| E-value          | 0          | N/A (always 0)                     |
| bit score        | 7546       | interpreted as the alignment score |

Note that the number of mismatches and gap openings are currently not displayed
in the result output. This will be addressed in a future version of the
package.

## Installation

### Using EDM

Users of the [Enthought Deployment Manager(EDM)](https://www.enthought.com/enthought-deployment-manager/)
can install the necessary prerequisites (Click, Cython, Numpy, and Parasail) by
importing an EDM environment from the bundle file shipped with this repository

```bash
  edm env import -f edm_requirements.json vpsearch
```
When this is done, activate the environment, and install this package. From the
root of this repository, run
```bash
  edm shell -e vpsearch
  pip install -e .
```

### Using Pip, Conda, etc.

Users of other package installation tools, such as Pip or Conda, need to
install the [Parasail](https://github.com/jeffdaily/parasail) library following
the instructions on the Parasail web page. Once that is done, the Python
dependencies can be installed using the appropriate command for your package
manager. For pip, for example, this can be done with
```bash
  pip install -r requirements.txt
```

Once that is done, activate your virtual environment, and install this package
via
```bash
  pip install -e .
```

### Troubleshooting

The vpsearch package relies on the Parasail C library for alignment. If
building the package fails because the Parasail library cannot be found, you
can manually specify the location of the Parasail include files and shared
object libraries by setting the `PARASAIL_INCLUDE_DIR` and `PARASAIL_LIB_DIR`
environment variables before building the package:
```bash
  export PARASAIL_INCLUDE_DIR=/location/of/parasail/include/files
  export PARASAIL_LIB_DIR=/location/of/parasail/lib/files
  pip install -e .
```
Note that if Parasail is installed in a non-standard location, you may have to
set the `LD_LIBRARY_PATH` variable at runtime.

## Implementation notes

The tree construction operates in two phases. We first build the tree as a tree
of Python object nodes because it's easier to build with a dynamic data
structure. Then it linearizes the topology of the nodes into a few integer
arrays that are easy to serialize and fast to look up. The object that
represents the linearized tree can only query the database, not build the tree.
The slower tree-of-nodes implementation can build and query (albeit with more
overhead).

## License

This package is licensed under the [BSD license](LICENSE.txt).

## References

Vantage point trees were introduced in

> Uhlmann, Jeffrey (1991). "Satisfying General Proximity/Similarity Queries
  with Metric Trees". Information Processing Letters. 40 (4):
  175–179. doi:10.1016/0020-0190(91)90074-r.

> Yianilos (1993). Data structures and algorithms for nearest neighbor search
  in general metric spaces (PDF). Fourth annual ACM-SIAM symposium on Discrete
  algorithms. Society for Industrial and Applied Mathematics Philadelphia, PA,
  USA. pp. 311–321. pny93.

The Parasail library is described in

> Daily, Jeff. (2016). Parasail: SIMD C library for global, semi-global, and
  local pairwise sequence alignments. BMC Bioinformatics, 17(1),
  1-11. doi:10.1186/s12859-016-0930-z
