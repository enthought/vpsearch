import argparse
import csv
import sys

from Bio import SeqIO


def read_primers(primers_file):
    """ Read forward and reverse primer from FASTA file.

    Assumes that the first sequence found is the forward primer, and the
    second one the reverse primer.

    """
    with open(primers_file, encoding="utf-8") as handle:
        primers = list(SeqIO.parse(handle, "fasta"))
    return str(primers[0].seq), str(primers[1].seq)


def accept_primer_locs(fwd, rev):
    """ Do some simple sanity checks on the locations of the found primers.

    Checks whether there are at most 3 mismatches in the parts of the sequence
    that were identified with the primers, and whether the length of the slice
    between the primers falls within some biologically relevant range.

    """
    assert fwd["primer_index"] == "1", fwd
    assert rev["primer_index"] == "2", rev

    mm_fwd = int(fwd["mismatches"])
    mm_rev = int(rev["mismatches"])
    length = int(rev["position"]) - int(fwd["position"])

    return mm_fwd <= 3 and mm_rev <= 3 and length > 250 and length <= 300


def slice_sequence(seq, fwd, rev, primers):
    """ Return the part of the sequence between the forward/reverse primers.
    """
    assert seq.name == fwd["#seqname"] == rev["#seqname"]

    p_fwd = int(fwd["position"])
    p_rev = int(rev["position"]) - len(primers[1])
    return seq[p_fwd:p_rev]


def cut_primers(primers, primer_locs, fasta):
    """ Cut out sequence part between reported primer locations.
    """
    n_reject = 0
    with open(fasta, encoding="utf-8") as fa_handle:
        with open(primer_locs, encoding="utf-8") as locs_handle:
            seqs = SeqIO.parse(fa_handle, "fasta")
            reader = csv.DictReader(locs_handle, delimiter="\t")
            for seq, fwd, rev in zip(seqs, reader, reader):
                if not accept_primer_locs(fwd, rev):
                    continue
                cut_seq = slice_sequence(seq, fwd, rev, primers)
                if cut_seq is not None:
                    SeqIO.write(cut_seq, sys.stdout, "fasta-2line")
                else:
                    n_reject += 1

    print(f"Rejected: {n_reject}", file=sys.stderr)


def main():
    p = argparse.ArgumentParser()
    p.add_argument("primers")
    p.add_argument("primer_locs")
    p.add_argument("fasta")
    ns = p.parse_args()

    primers = read_primers(ns.primers)
    cut_primers(primers, ns.primer_locs, ns.fasta)


if __name__ == "__main__":
    main()
