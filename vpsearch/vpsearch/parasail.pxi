cdef extern from "parasail.h":
    ctypedef struct parasail_result_t:
        # Keep opaque
        pass

    ctypedef struct parasail_matrix_t:
        # Keep opaque
        pass

    ctypedef struct parasail_profile_t:
        # Keep opaque
        pass

    void parasail_profile_free(parasail_profile_t *profile)
    void parasail_result_free(parasail_result_t *result) nogil

    ctypedef parasail_result_t* parasail_pfunction_t(
        parasail_profile_t * profile,
        char * s2, int s2Len,
        int open, int gap) nogil
    ctypedef parasail_result_t* parasail_function_t(
        char * s1, int s1Len,
        char * s2, int s2Len,
        int open, int gap,
        parasail_matrix_t *matrix) nogil

    parasail_function_t * parasail_lookup_function(char *funcname)
    parasail_pfunction_t * parasail_lookup_pfunction(char *funcname)
    parasail_matrix_t* parasail_matrix_lookup(char *matrixname)
    parasail_matrix_t* parasail_matrix_create(
        char *alphabet, int match, int mismatch)
    parasail_matrix_t* parasail_matrix_from_file(char *filename)
    void parasail_matrix_free(parasail_matrix_t *matrix)

    parasail_profile_t* parasail_profile_create_stats_16(
        char * s1, int s1Len,
        parasail_matrix_t* matrix)
    void parasail_profile_free(parasail_profile_t *profile)

    int parasail_result_is_nw(parasail_result_t * result)
    int parasail_result_is_sg(parasail_result_t * result)
    int parasail_result_is_sw(parasail_result_t * result)
    int parasail_result_is_saturated(parasail_result_t * result)
    int parasail_result_is_banded(parasail_result_t * result)
    int parasail_result_is_scan(parasail_result_t * result)
    int parasail_result_is_striped(parasail_result_t * result)
    int parasail_result_is_diag(parasail_result_t * result)
    int parasail_result_is_blocked(parasail_result_t * result)
    int parasail_result_is_stats(parasail_result_t * result)
    int parasail_result_is_stats_table(parasail_result_t * result)
    int parasail_result_is_stats_rowcol(parasail_result_t * result)
    int parasail_result_is_table(parasail_result_t * result)
    int parasail_result_is_rowcol(parasail_result_t * result)
    int parasail_result_is_trace(parasail_result_t * result)

    int parasail_result_get_score(parasail_result_t * result) nogil
    int parasail_result_get_end_query(parasail_result_t * result)
    int parasail_result_get_end_ref(parasail_result_t * result)

    int parasail_result_get_matches(parasail_result_t * result)
    int parasail_result_get_similar(parasail_result_t * result)
    int parasail_result_get_length(parasail_result_t * result)

    int* parasail_result_get_score_table(parasail_result_t * result)
    int* parasail_result_get_matches_table(parasail_result_t * result)
    int* parasail_result_get_similar_table(parasail_result_t * result)
    int* parasail_result_get_length_table(parasail_result_t * result)
    int* parasail_result_get_score_row(parasail_result_t * result)
    int* parasail_result_get_matches_row(parasail_result_t * result)
    int* parasail_result_get_similar_row(parasail_result_t * result)
    int* parasail_result_get_length_row(parasail_result_t * result)
    int* parasail_result_get_score_col(parasail_result_t * result)
    int* parasail_result_get_matches_col(parasail_result_t * result)
    int* parasail_result_get_similar_col(parasail_result_t * result)
    int* parasail_result_get_length_col(parasail_result_t * result)
    int* parasail_result_get_trace_table(parasail_result_t * result)
    int* parasail_result_get_trace_ins_table(parasail_result_t * result)
    int* parasail_result_get_trace_del_table(parasail_result_t * result)


cdef extern from "parasail/io.h":
    ctypedef struct parasail_string_t:
        size_t l
        char *s

    ctypedef struct parasail_sequence_t:
        parasail_string_t name
        parasail_string_t comment
        parasail_string_t seq
        parasail_string_t qual

    ctypedef struct parasail_sequences_t:
        parasail_sequence_t *seqs
        size_t l
        size_t characters
        size_t shortest
        size_t longest
        float mean
        float stddev

    parasail_sequences_t* parasail_sequences_from_file(char *fname)
    void parasail_sequences_free(parasail_sequences_t *sequences)


cdef extern from "parasail/matrices/nuc44.h":
    cdef parasail_matrix_t parasail_nuc44

