"""
(C) Copyright 2010-2019 Enthought, Inc., Austin, TX
All Rights Reserved.

This software is provided without warranty under the terms of the BSD license
included in LICENSE.txt and may be redistributed only under the conditions
described in the aforementioned license.  The license is also available online
at: https://github.com/enthought/vpsearch.

Thanks for using Enthought open source!

"""

cimport cython
from libc.stddef cimport size_t
from libcpp.pair cimport pair
from libcpp.stack cimport stack as cpp_stack
from cpython.bytes cimport PyBytes_FromStringAndSize

from cython.operator cimport dereference as deref, preincrement as inc

from collections import deque
import os

cimport numpy as cnp
import numpy as np

include 'parasail.pxi'

cdef extern from "fastqueue.hpp":
    cdef cppclass FastQueue:
        FastQueue()
        FastQueue(size_t)
        void push(float, size_t) nogil
        float get_max_distance() nogil

        cppclass iterator:
            pair[float, size_t] operator*()
            iterator operator++()
            bint operator==(iterator)
            bint operator!=(iterator)

        iterator begin()
        iterator end()


cdef parasail_matrix_t* _create_modified_nuc44():
    """ Create a modified version of the nuc44 substitution matrix.

    The modified version has +1 on the diagonal for ambiguous nucleotides
    (compared to the original nuc44, which has -1), but is otherwise the
    same as nuc44. This modification is necessary for the alignment
    distance to be a true distance metric, otherwise one could have e.g.
    d(A, N) == 0.

    See GH # 263 for more details.

    """
    cdef parasail_matrix_t* mod_nuc44
    cdef size_t i

    mod_nuc44 = parasail_matrix_copy(&parasail_nuc44)
    for i in range(4, 16):
        parasail_matrix_set_value(mod_nuc44, i, i, 1)
    return mod_nuc44

cdef parasail_matrix_t MOD_NUC44 = deref(_create_modified_nuc44())


# The default scoring parameters were taken from fasta-36.3.7
#  match = +5
#  mismath = -4
#  gap_open = -12
#  gap_extend = -4


cpdef int self_aligned_score(char* seq, size_t length) nogil:
    """
    Align sequence to itself and return the alignment score.

    This method allows seq to contain ambiguous nucleotides and uses the nuc44
    substitution matrix.

    Match score (unambiguous character): 5
    Match score (ambiguous character): 1 (modified nuc44)
    """
    cdef const parasail_matrix_t *matrix = &MOD_NUC44
    cdef int s = 0
    cdef size_t i
    for i in range(length):
        s += matrix.matrix[(matrix.size + 1) * matrix.mapper[<size_t>seq[i]]]
    return s


cdef class SeqDB:
    cdef parasail_sequences_t *sequences

    def __cinit__(self, str filename):
        # We test explicitly whether `filename` points to an existing file,
        # since `parasail_sequences_from_file` will do a hard exit(1) if the
        # file does not exist.
        if not os.path.exists(filename):
            raise FileNotFoundError(filename)

        self.sequences = parasail_sequences_from_file(filename.encode())

    def __dealloc__(self):
        if self.sequences != NULL:
            parasail_sequences_free(self.sequences)
            self.sequences = NULL

    def find_best_match(self, bytes sequence, search_type='nw',
                        vectorization='scan', int gap_open=12,
                        int gap_extend=4):
        cdef parasail_profile_t* profile
        cdef size_t i
        cdef int best_score, current_score
        cdef parasail_sequence_t* best_seq = NULL
        cdef parasail_sequence_t* current_seq
        cdef parasail_pfunction_t* align_func = NULL
        cdef parasail_result_t* result
        cdef double match_percent
        cdef object result_id

        func_id = '{}_{}_profile_16'.format(search_type, vectorization).encode()
        align_func = parasail_lookup_pfunction(func_id)
        if align_func == NULL:
            raise KeyError('Failed to find {0!r}'.format(func_id))

        profile = parasail_profile_create_stats_16(
            sequence, len(sequence), &MOD_NUC44)

        best_score = -1000000
        with nogil:
            for i in range(self.sequences.l):
                current_seq = &self.sequences.seqs[i]
                result = align_func(profile, current_seq.seq.s, current_seq.seq.l,
                                    gap_open, gap_extend)
                current_score = parasail_result_get_score(result)
                if current_score > best_score:
                    best_score = current_score
                    best_seq = current_seq
                parasail_result_free(result)

        if best_seq != NULL:
            # Try again with stats to get the number of matches.
            align_func = parasail_lookup_pfunction('{}_stats_{}_profile_16'.format(
                search_type, vectorization).encode())
            result = align_func(profile, best_seq.seq.s, best_seq.seq.l,
                                gap_open, gap_extend)
            result_id = best_seq.name.s
            match_percent = (100.0 * parasail_result_get_matches(result)
                             / parasail_result_get_length(result))
            parasail_result_free(result)
            best_seq = NULL

        parasail_profile_free(profile)

        return result_id, match_percent

    def __len__(self):
        return self.sequences.l

    def __getitem__(self, i):
        cdef parasail_sequence_t* seq
        if not isinstance(i, (int, long)):
            raise TypeError("expect an integer for indexing")
        if i < 0:
            i += len(self)
        if i < 0:
            raise IndexError("indexing before the beginning")
        if i > len(self):
            raise IndexError("indexing past the end")
        seq = &self.sequences.seqs[i]
        return ((i, PyBytes_FromStringAndSize(seq.name.s, seq.name.l)),
                PyBytes_FromStringAndSize(seq.seq.s, seq.seq.l))

    def __iter__(self):
        for i in range(len(self)):
            yield self[i]


@cython.cdivision(True)
cpdef double scoredistance(query, ref, int gap_open=12, int gap_extend=4):
    cdef bytes qseq
    cdef bytes rseq
    cdef parasail_function_t* align_func = NULL
    cdef parasail_result_t* result
    cdef double dist

    if isinstance(query, tuple):
        # (id, seq) pair
        query = query[1]
    if isinstance(query, bytes):
        qseq = query
    elif isinstance(query, unicode):
        qseq = query.encode('ascii')
    if isinstance(ref, tuple):
        # (id, seq) pair
        ref = ref[1]
    if isinstance(ref, bytes):
        rseq = ref
    elif isinstance(ref, unicode):
        rseq = ref.encode('ascii')

    align_func = parasail_lookup_function(b'nw_scan_16')
    result = align_func(qseq, len(qseq), rseq, len(rseq), gap_open, gap_extend,
                        &MOD_NUC44)
    # Score-based distance metric.
    #   d(q, r) = score(q, q) + score(r, r) - 2*score(q, r)
    dist = (
        self_aligned_score(qseq, len(qseq))
        + self_aligned_score(rseq, len(rseq))
        - 2.0 * parasail_result_get_score(result))
    parasail_result_free(result)
    return dist


@cython.cdivision(True)
cpdef double matchpct(query, ref, int gap_open=12, int gap_extend=4):
    cdef bytes qseq
    cdef bytes rseq
    cdef parasail_function_t* align_func = NULL
    cdef parasail_result_t* result
    cdef double dist

    if isinstance(query, tuple):
        # (id, seq) pair
        query = query[1]
    if isinstance(query, bytes):
        qseq = query
    elif isinstance(query, unicode):
        qseq = query.encode('ascii')
    if isinstance(ref, tuple):
        # (id, seq) pair
        ref = ref[1]
    if isinstance(ref, bytes):
        rseq = ref
    elif isinstance(ref, unicode):
        rseq = ref.encode('ascii')

    align_func = parasail_lookup_function(b'nw_stats_scan_16')
    result = align_func(qseq, len(qseq), rseq, len(rseq), gap_open, gap_extend,
                        &MOD_NUC44)
    dist = (100.0 * parasail_result_get_matches(result)
            / <double>parasail_result_get_length(result))
    parasail_result_free(result)
    return dist


cdef class NeighborQueue:
    cdef public list queue
    cdef public cnp.int64_t size

    def __init__(self, size):
        self.size = size
        self.queue = []

    cdef void push(self, object item):
        self.queue.append(item)
        self.queue.sort()
        if len(self.queue) > self.size:
            self.queue.pop()

    cdef float peekright(self):
        return self.queue[-1][0]

    @property
    def full(self):
        return len(self.queue) == self.size


cdef class MatchRecord:
    cdef public bytes seqid
    cdef public double matchpct, e_value, bit_score, distance
    cdef public long length, matches, mismatches, qlen, rlen, gap_openings, score

    @classmethod
    def align(cls, query, ref):
        cdef MatchRecord self
        cdef bytes rseq
        cdef parasail_function_t* align_func = NULL
        cdef parasail_result_t* result

        self = cls()
        self.seqid = ref[0][1]
        rseq = ref[1]
        self.qlen = len(query)
        self.rlen = len(ref[1])

        align_func = parasail_lookup_function(b'nw_stats_scan_16')
        result = align_func(query, len(query), rseq, len(rseq), 12, 4,
                            &MOD_NUC44)
        self.score = parasail_result_get_score(result)
        self.distance = (
            self_aligned_score(query, self.qlen)
            + self_aligned_score(rseq, self.rlen)
            - 2.0 * self.score)
        self.length = parasail_result_get_length(result)
        self.matches = parasail_result_get_matches(result)
        self.matchpct = (100.0 * <float>self.matches / self.length)
        # FIXME: ought to be able to compute this from the traceback, but it's annoying.
        self.mismatches = 0
        self.gap_openings = 0
        # Stubs.
        self.e_value = 0.0
        self.bit_score = 0.0
        parasail_result_free(result)
        return self

    def to_tuple(self):
        return (
            self.seqid.decode(),
            self.matchpct,
            self.length,
            self.mismatches,
            self.gap_openings,
            1,
            self.qlen,
            1,
            self.rlen,
            self.e_value,
            self.score,
        )

    def __str__(self):
        # FIXME: The last one ought to be bit_score, but eh.
        fmt = '{}\t{:.2f}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{:g}\t{}'
        return fmt.format(*self.to_tuple())

    def __repr__(self):
        return '<{0.__name__}: {1.seqid} {0.matchpct:f}>'.format(type(self), self)


cdef class LinearVPTree:
    """ Linearized VPTree for serialization and fast searches.
    """
    cdef public SeqDB sequences
    cdef public object distance
    cdef public object seqids
    cdef public object mus
    cdef public object inside_ptr
    cdef public object outside_ptr

    def __cinit__(self):
        self.distance = scoredistance

    @classmethod
    def fromfiles(cls, fastafile, treefile):
        cdef LinearVPTree self

        self = cls()
        self.sequences = SeqDB(fastafile)
        d = np.load(treefile)
        for attr in 'seqids mus inside_ptr outside_ptr'.split():
            setattr(self, attr, d[attr])
        return self

    @classmethod
    def fromtree(cls, db, tree):
        cdef LinearVPTree self
        cdef dict node2k

        self = cls()
        self.sequences = db
        node2k = {}
        for k, node in enumerate(tree.preorder()):
            node2k[node] = k
        n_nodes = len(node2k)
        self.seqids = np.full(n_nodes, -1, dtype=np.int64)
        self.mus = np.full(n_nodes, np.inf, dtype=np.float32)
        self.inside_ptr = np.full(n_nodes, -1, dtype=np.int64)
        self.outside_ptr = np.full(n_nodes, -1, dtype=np.int64)
        for k, node in enumerate(tree.preorder()):
            self.seqids[k] = node.vantage[0][0]
            self.mus[k] = node.mu
            self.inside_ptr[k] = node2k.get(node.inside, -1)
            self.outside_ptr[k] = node2k.get(node.outside, -1)
        return self

    @classmethod
    def fromdir(cls, root):
        fastafile = os.path.join(root, 'sequences.fa')
        treefile = os.path.join(root, 'indices.npz')
        return cls.fromfiles(fastafile, treefile)

    def save(self, treefile):
        kwds = {}
        for attr in 'seqids mus inside_ptr outside_ptr'.split():
            kwds[attr] = getattr(self, attr)
        np.savez(treefile, **kwds)

    @cython.boundscheck(False)
    def get_nearest_neighbors(self, bytes query, size=1):
        cdef FastQueue neighbors
        cdef cnp.int64_t[::1] seqids, inside_ptr, outside_ptr
        cdef float[::1] mus
        cdef cnp.int64_t nodeid
        cdef cnp.int64_t k, k_in, k_out
        cdef long len_query
        cdef float mu, tau, distance
        cdef parasail_profile_t* profile
        cdef parasail_pfunction_t* align_func = NULL
        cdef parasail_sequence_t* vantage_seq
        cdef parasail_result_t* result
        cdef char* c_query = <char*> query

        seqids = self.seqids
        mus = self.mus
        inside_ptr = self.inside_ptr
        outside_ptr = self.outside_ptr

        func_id = b'nw_scan_profile_16'
        align_func = parasail_lookup_pfunction(func_id)
        if align_func == NULL:
            raise KeyError('Failed to find {0!r}'.format(func_id))
        len_query = len(query)
        profile = parasail_profile_create_stats_16(
            query, len_query, &MOD_NUC44)

        neighbors = FastQueue(size)
        tau = neighbors.get_max_distance()

        cdef cpp_stack[cnp.int64_t] stack = cpp_stack[cnp.int64_t]()
        stack.push(0)

        with nogil:
            while not stack.empty():
                # Depth-first traversal.
                k = stack.top()
                stack.pop()
                if k < 0:
                    # -1 is the sentinel value.
                    continue
                nodeid = seqids[k]
                vantage_seq = &(self.sequences.sequences.seqs[nodeid])
                result = align_func(
                    profile, vantage_seq.seq.s, vantage_seq.seq.l, 12, 4
                )
                distance = (
                    self_aligned_score(c_query, len_query)
                    + self_aligned_score(vantage_seq.seq.s, vantage_seq.seq.l)
                    - 2.0 * parasail_result_get_score(result))
                parasail_result_free(result)
                if distance < tau:
                    neighbors.push(distance, nodeid)
                    tau = neighbors.get_max_distance()
                k_in = inside_ptr[k]
                k_out = outside_ptr[k]
                mu = mus[k]
                if distance < mu:
                    # With the depth-first traversal, we will first search the last
                    # item, so append in reverse order of how we want to traverse.
                    if distance >= mu - tau:
                        stack.push(k_out)
                    if distance <= mu + tau:
                        stack.push(k_in)
                else:
                    if distance <= mu + tau:
                        stack.push(k_in)
                    if distance >= mu - tau:
                        stack.push(k_out)

        parasail_profile_free(profile)
        matches = []
        cdef FastQueue.iterator it = neighbors.begin()
        while it != neighbors.end():
            seq = self.sequences[deref(it).second]
            matches.append(MatchRecord.align(query, seq))
            inc(it)
        matches.sort(key=lambda r: -r.matchpct)
        return matches

    def _traceup(self, ref_name):
        """ Debugging method to find the path from the root to the specified
        sequence.
        """
        cdef cnp.int64_t i, k, nodeid
        cdef parasail_sequence_t *seq
        cdef cnp.int64_t[::1] seqids, inside_ptr, outside_ptr
        cdef float[::1] mus
        cdef cnp.int64_t n_nodes

        seqids = self.seqids
        mus = self.mus
        inside_ptr = self.inside_ptr
        outside_ptr = self.outside_ptr
        n_nodes = len(self.seqids)

        for k in range(n_nodes):
            nodeid = seqids[k]
            seq = &(self.sequences.sequences.seqs[nodeid])
            name = PyBytes_FromStringAndSize(seq.name.s, seq.name.l)
            if name == ref_name:
                break
        else:
            raise KeyError("Could not find sequence ID {}".format(ref_name))

        ref_seq = self.sequences[nodeid]
        path = [(k, 'target', mus[k])]
        while True:
            for i in range(n_nodes):
                if inside_ptr[i] == k:
                    path.append((i, 'inside', mus[i]))
                    k = i
                    break
                if outside_ptr[i] == k:
                    path.append((i, 'outside', mus[i]))
                    k = i
                    break
            else:
                break
        named_path = []
        for i, branch, mu in path[::-1]:
            nodeid = seqids[i]
            seq = &(self.sequences.sequences.seqs[nodeid])
            name = PyBytes_FromStringAndSize(seq.name.s, seq.name.l)
            named_path.append((i, name, branch, mu,
                               scoredistance(ref_seq, self.sequences[nodeid])))
        return named_path


cdef class VPTree:
    """ Slower but more flexible VP-tree for building the tree in-memory.

    This is used to build the tree. Then this is converted to the LinearVPTree
    for serialization and fast searches.
    """
    cdef public object vantage
    cdef public double mu
    cdef public VPTree inside
    cdef public VPTree outside
    cdef public object distance
    cdef public object prng
    cdef public long n_sample_vantages
    cdef public long n_sample_test_points
    cdef public long sampling_cutoff

    def __cinit__(self, **kwds):
        self.mu = 0.0
        self.distance = scoredistance
        self.prng = np.random.RandomState(0x8d278e75)
        self.n_sample_vantages = 5
        self.n_sample_test_points = 20
        self.sampling_cutoff = 100

    def __init__(self, **kwds):
        for attr, value in kwds.items():
            setattr(self, attr, value)

    @classmethod
    def build(cls, list points, **kwds):
        cdef VPTree self

        self = cls(**kwds)

        # Copy the list as we will be modifying it.
        points = list(points)
        self.vantage = self.select_vantage(points)
        distances = np.array([self.distance(self.vantage, p) for p in points])
        if (distances == 0.0).any():
            # FIXME: Not sure if this is necessary any more. But for this
            # database, we do want to error out early.
            raise ValueError("Vantage point {0.vantage[0]} is a duplicate.")
        inner_points = []
        outer_points = []
        if len(points) == 1:
            self.mu = distances[0]
            inner_points = []
            outer_points = points
        elif len(points) >= 2:
            i_mid = len(distances) // 2
            i_part = np.argpartition(distances, i_mid)
            self.mu = distances[i_part[i_mid]]
            # The median may not be unique. This is okay if we use >= and <=
            # comparisons during the lookup. Keeping balance is worth the cost
            # of occasionally having more branches to go down.
            inner_points = [points[i] for i in i_part[:i_mid]]
            outer_points = [points[i] for i in i_part[i_mid:]]
        assert len(inner_points) + len(outer_points) == len(points)
        if inner_points:
            self.inside = VPTree.build(inner_points, distance=self.distance,
                                       prng=self.prng)
        if outer_points:
            self.outside = VPTree.build(outer_points, distance=self.distance,
                                        prng=self.prng)
        return self

    @property
    def is_leaf(self):
        return self.inside is None and self.outside is None

    @property
    def depth(self):
        child_depth = 0
        if self.inside is not None:
            child_depth = max(child_depth, self.inside.depth)
        if self.outside is not None:
            child_depth = max(child_depth, self.outside.depth)
        depth = child_depth + 1
        return depth

    def iteridx(self, k=0):
        """ Do a pre-order traversal yielding the index into the flattened
        array.
        """
        yield k, self
        k_in = 2 * k + 1
        k_out = k_in + 1
        if self.inside is not None:
            for i, node in self.inside.iteridx(k_in):
                yield i, node
        if self.outside is not None:
            for i, node in self.outside.iteridx(k_out):
                yield i, node

    def select_vantage(self, list points):
        if len(points) >= self.sampling_cutoff:
            return self._sample_select_vantage(points)
        else:
            return self._simple_select_vantage(points)

    def _sample_select_vantage(self, list points):
        n = self.n_sample_vantages + self.n_sample_test_points
        idxs = set()
        while len(idxs) < n:
            idxs.add(self.prng.randint(len(points)))
        idxs = list(idxs)
        self.prng.shuffle(idxs)
        vantage_samples = idxs[:self.n_sample_vantages]
        test_samples = idxs[self.n_sample_vantages:]
        variances = {}
        for i in vantage_samples:
            distances = []
            for j in test_samples:
                distances.append(self.distance(points[i], points[j]))
            distances = np.array(distances)
            mu = np.median(distances)
            variances[i] = ((distances - mu) ** 2).sum()
        best_i = max(variances, key=variances.get)
        vantage = points.pop(best_i)
        return vantage

    def _simple_select_vantage(self, list points):
        i = self.prng.randint(len(points))
        vantage = points.pop(i)
        return vantage

    def __iter__(self):
        stack = deque([self])
        while stack:
            n = stack.popleft()
            yield n
            if n is not None and not n.is_leaf:
                stack.extend([n.inside, n.outside])

    def preorder(self):
        """ Pre-order traversal, ignoring empty nodes.
        """
        yield self
        if self.inside is not None:
            for node in self.inside.preorder():
                yield node
        if self.outside is not None:
            for node in self.outside.preorder():
                yield node

    @property
    def size(self):
        size = 1
        if self.inside is not None:
            size += self.inside.size
        if self.outside is not None:
            size += self.outside.size
        return size

    def get_nearest_neighbors(self, query, k=1):
        cdef NeighborQueue neighbors
        cdef VPTree node

        neighbors = NeighborQueue(k)
        tau = np.inf
        stack = deque([self])
        while stack:
            node = stack.popleft()
            if node is None:
                continue
            distance = self.distance(query, node.vantage)
            if distance < tau:
                neighbors.push((distance, node.vantage))
                if neighbors.full:
                    tau, _ = neighbors.peekright()
            if node.inside is None and node.outside is None:
                continue
            if distance < node.mu:
                stack.append(node.inside)
                if distance >= node.mu - tau:
                    stack.append(node.outside)
            else:
                stack.append(node.outside)
                if distance <= node.mu + tau:
                    stack.append(node.inside)
        return neighbors.queue
