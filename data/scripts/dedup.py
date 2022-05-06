import argparse
import sys

from Bio import SeqIO


def _parse_args():
    p = argparse.ArgumentParser()
    p.add_argument("input")
    return p.parse_args().input


def _seq_generator(handle):
    seen = set()
    for record in SeqIO.parse(handle, "fasta"):
        seq = str(record.seq).upper()
        if seq not in seen:
            seen.add(seq)
            record.seq = record.seq.upper()
            yield record


def main():
    fname = _parse_args()
    with open(fname, encoding="utf-8") as handle:
        SeqIO.write(_seq_generator(handle), sys.stdout, "fasta")


if __name__ == "__main__":
    main()
