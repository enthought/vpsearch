============
Installation
============

Using wheels (recommended)
--------------------------

The vpsearch package is available from the Python Package Index (PyPI) and can
be installed using `pip` as follows::

    python -m pip install vpsearch

On supported platforms (Linux, Intel macOS), this will install a binary wheel
that includes the Parasail dependency. On other platforms, vpsearch can be
installed from source, and instructions on how to do so can be found below.

Users of Apple Silicon should compile the package from scratch using the
instructions below. Note that vpsearch depends on Parasail, a library for fast
alignment using Intel-specific SIMD instruction sets. These are not supported
on Apple Silicon and even though vpsearch can be made to run on this platform,
it will be slow.

Using Docker
------------

It is possible to build a Docker image that contains vpsearch as well as all of
its dependencies. This is useful, for example, when integrating vpsearch into a
workflow manager, like Snakemake, CWL, or WDL.

To build the image, run the following command from the root of this repository::

    docker build . -t vpsearch-image

Once the image has been built, vpsearch can then be run from within a
container. Assuming you have a FASTA file of target sequences in the file
``database.fasta`` in the current directory, run the following to build a
vpsearch index::

    docker run -it -v $PWD:/data -t vpsearch-image vpsearch build /data/database.fasta

To query the index for a given FASTA file `query.fasta` of query sequences,
run::

    docker run -it -v $PWD:/data -t vpsearch-image vpsearch query /data/database.db /data/query.fasta

.. _installation-development:    

From source (development environment)
-------------------------------------

For platforms where no binary wheel is available, or in order to contribute to
the codebase, it is necessary to install the package from source. To do so, you
will need a C and C++ compiler with support for the AVX2 and AVX512 instruction
sets (on Linux, version 4.9.2 and up of the gcc/g++ compiler will do, while on
macOS any recent version of clang is sufficient).

Using pip, the package can be installed in development mode in your Python
environment in the normal way::

    python -m pip install -e .

To verify that everything works as expected, you can run the unit test suite
via::

    python -m unittest discover -v vpsearch
