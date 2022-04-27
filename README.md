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
illustration, we build a vantage point tree for a database of sequences
obtained by trimming the GTDB 16S database to the v3-v4 hypervariable
region. This database contains 10875 unique sequences, and can be found (in
compressed form) in the `data/` directory inside this repository.
```console
  $ vpsearch build bac120_ssu_reps_r207-sliced-dedup.fa
  Building for 10875 sequences...done.
  Linearizing...done.
  Database created in bac120_ssu_reps_r207-sliced-dedup.db
```

As this is a relatively small database, the process finishes quickly, in about
10 seconds. For larger databases, such as the RDP database of full length
sequences, this may take longer. For example, building an index for the RDP
database takes about 20 minutes on a standard machine.

Once a tree has been built, unknown sequences can be looked up using the
`vpsearch query` command. Here we supply a query file with a single
sequence. The `query.fa` file can also be found in the `data/` directory and
represents a Lactobacillus helsingborgensis sample whose sequence was
downloaded from RefSeq. We see that we have a perfect match with
`RS_GCF_000970855.1`, which happens to be the same sequence. Other matches are
highly similar but not identical, and represent different species of
Lactobacillus (kimbladii, melliventris, and panisapium, respectively).

```console
  $ vpsearch query bac120_ssu_reps_r207-sliced-dedup.db query.fa
  NR_126253.1     RS_GCF_000970855.1      100.00  253     0       0       1       253     1       253     0       1265
  NR_126253.1     RS_GCF_014323605.1      98.81   253     0       0       1       253     1       253     0       1238
  NR_126253.1     RS_GCF_013346935.1      98.02   253     0       0       1       253     1       253     0       1220
  NR_126253.1     RS_GCF_002916935.1      97.63   253     0       0       1       253     1       253     0       1211
```
By default, the `vpsearch query` command outputs the best four matches in the
database per query sequence (the number of matches can be changed with the `-k`
parameter). Lookup is done one query sequence at a time, but multiple queries
can be considered in parallel by enabling multiple threads; use the `-j` option
to specify the number of threads.

The `vpsearch query` command attempts to output its results in the standard
BLAST tabular format. The interpretation of the columns is as follows:

| Column name      | Example            | Notes                              |
|------------------|--------------------|------------------------------------|
| query ID         | NR_126253.1        |                                    |
| subject ID       | RS_GCF_014323605.1 |                                    |
| % identity       | 98.81              |                                    |
| alignment length | 253                |                                    |
| mismatches       | 0                  | currently not implemented          |
| gap openings     | 0                  | currently not implemented          |
| query start      | 1                  |                                    |
| query end        | 253                |                                    |
| subject start    | 1                  |                                    |
| subject end      | 253                |                                    |
| E-value          | 0                  | N/A (always 0)                     |
| bit score        | 1238               | interpreted as the alignment score |

Note that the number of mismatches and gap openings are currently not displayed
in the result output. This will be addressed in a future version of the
package.

## Installation

### Using EDM

Users of the [Enthought Deployment Manager(EDM)](https://www.enthought.com/enthought-deployment-manager/)
can install the necessary prerequisites (Click, Cython, Numpy, and Parasail) by
importing an EDM environment from the bundle file shipped with this repository

```bash
  edm env import -f <bundle.json> vpsearch
```
where `<bundle.json>` is one of `vpsearch_py3.8_osx-x86_64.json` or
`vpsearch_py3.8_rh7-x86_64.json`, depending on your platform.

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

### Using Docker

It is possible to build a Docker image that contains vpsearch as well as all of
its dependencies. This is useful, for example, when integrating vpsearch into a
workflow manager, like Snakemake, CWL, or WDL.

To build the image, run the following command from the root of this repository:
```bash
  docker build . -t vpsearch-image
```

Once the image has been built, vpsearch can then be run from within a
container. Assuming you have a FASTA file of target sequences in the file
`database.fasta` in the current directory, run the following to build a
vpsearch index:
```bash
  docker run -it -v $PWD:/data -t vpsearch-image vpsearch build /data/database.fasta
```

To query the index for a given FASTA file `query.fasta` of query sequences,
run:
```bash
  docker run -it -v $PWD:/data -t vpsearch-image vpsearch query /data/database.db /data/query.fasta
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

## Building wheels

Wheels for this package can be built in a platform-independent way using
[cibuildwheel](https://cibuildwheel.readthedocs.io/en/stable/), running under
GitHub actions. As an administrator, you can start a workflow to build wheels
by selecting the "Build wheels" action from the GitHub actions menu, and
clicking the "Run workflow" button. When the workflow completes, wheels for
Linux and macOS will be available as a zipped artifact.

It is possible to run cibuildwheels locally, but only to build wheels for
Linux. In a clean Python environment, run `pip install cibuildwheel` to install
the tool, followed by e.g.
```bash
  CIBW_BUILD_VERBOSITY=1 \
  CIBW_BUILD=cp38-manylinux_x86_64 \
  CIBW_BEFORE_BUILD="./ci/build-parasail.sh" \
  python -m cibuildwheel --output-dir wheelhouse --platform linux
```
to build Python 3.8 wheels for Linux. By varying the build tag, wheels for
other Python versions can be built. 

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
