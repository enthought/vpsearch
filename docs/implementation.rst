====================
Implementation notes
====================

The tree construction operates in two phases. We first build the tree as a tree
of Python object nodes because it's easier to build with a dynamic data
structure. Then it linearizes the topology of the nodes into a few integer
arrays that are easy to serialize and fast to look up. The object that
represents the linearized tree can only query the database, not build the tree.
The slower tree-of-nodes implementation can build and query (albeit with more
overhead).

vpsearch is best suited for indexing sets of small-ish marker genes, such as
the bacterial 16S rRNA gene or the fungal ITS region (100s-1000s of basepairs),
and has been tested with databases of hundreds of thousands of sequences. In
general, vpsearch is able to construct the tree using (on average) ``O(n log n)``
sequence comparisons and uses ``O(n)`` memory to do so, where ``n`` is the number
of sequences in the database. Each sequence comparison involves a global
sequence alignment, which scales quadratically with the length of the sequence.
For short sequences this can be done quickly and efficiently, but for longer
sequences (e.g. full length viral or bacterial genomes), the total runtime and
memory usage can be considerable.  If you are interested in using vpsearch
under these conditions, please open an issue!
