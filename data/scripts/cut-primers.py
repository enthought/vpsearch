import argparse
import csv
import sys

from Bio import SeqIO

FWD = "GTGCCAGCMGCCGCGGTAA"  # 515f primer
REV = "ATTAGAWADDDBDGTAGTCC"  # 806r primer


def cut_primer(seq, fwd, rev):
    assert fwd["primer_index"] == "1", fwd
    assert rev["primer_index"] == "2", rev
    assert seq.name == fwd["#seqname"] == rev["#seqname"]

    mm_fwd = int(fwd["mismatches"])
    mm_rev = int(rev["mismatches"])

    p_fwd = int(fwd["position"])
    p_rev = int(rev["position"])
    length = p_rev - p_fwd

    if mm_fwd > 3 or mm_rev > 3 or length < 250 or length > 300:
        # reject the sequence
        return None

    return seq[p_fwd : p_rev - len(REV)]


def cut_primers(primer_locs, fasta):
    n_reject = 0
    with open(fasta) as fa_handle:
        with open(primer_locs) as locs_handle:
            seqs = SeqIO.parse(fa_handle, "fasta")
            reader = csv.DictReader(locs_handle, delimiter="\t")
            for seq, fwd, rev in zip(seqs, reader, reader):
                cut_seq = cut_primer(seq, fwd, rev)
                if cut_seq is not None:
                    SeqIO.write(cut_seq, sys.stdout, "fasta-2line")
                else:
                    n_reject += 1

    print(f"Rejected: {n_reject}", file=sys.stderr)


def main():
    p = argparse.ArgumentParser()
    p.add_argument("primer_locs")
    p.add_argument("fasta")
    ns = p.parse_args()

    cut_primers(ns.primer_locs, ns.fasta)


if __name__ == "__main__":
    main()
