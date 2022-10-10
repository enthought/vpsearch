----------------------------------------------------------------
vpsearch - Fast Vantage-Point Tree Search for Sequence Databases
----------------------------------------------------------------

[![PyPI version](https://badge.fury.io/py/vpsearch.svg)](https://badge.fury.io/py/vpsearch)
![Tests status](https://github.com/enthought/vpsearch/actions/workflows/run-tests.yaml/badge.svg?event=push)
[![DOI](https://joss.theoj.org/papers/10.21105/joss.04236/status.svg)](https://doi.org/10.21105/joss.04236)

This is a package for indexing and querying a sequence database for fast
nearest-neighbor search by means of [vantage point
trees](https://en.wikipedia.org/wiki/Vantage-point_tree). For reasonably large
databases, such as [RDP](https://rdp.cme.msu.edu/), this results in sequence
lookups that are typically 5-10 times faster than other alignment-based lookup
methods.

Vantage-point tree search uses global-to-global alignment to compare sequences,
rather than seed-and-extend approximative methods as used for example by
BLAST.

## Installation and usage

VPsearch can be installed and updated through pip:
```console
    pip install -U vpsearch
```

This will install a standalone command-line utility `vpsearch` into your
environment, which can be used to build and query a sequence database. For more information on how to do so, see the [documentation](https://vpsearch.readthedocs.io/en/latest/).

## Citing vpsearch

If you use vpsearch, please cite our paper:

- Joris Vankerschaver, Steven J. Kern, Robert Kern. _VPsearch: fast exact sequence similarity search for genomic sequences_. Journal of Open Source Software, 7(78), 4236, 2002. https://doi.org/10.21105/joss.04236

## License

This package is licensed under the [3-clause BSD license](LICENSE).

