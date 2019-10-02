"""
(C) Copyright 2010-2019 Enthought, Inc., Austin, TX
All Rights Reserved.

This software is provided without warranty under the terms of the BSD license
included in LICENSE.txt and may be redistributed only under the conditions
described in the aforementioned license.  The license is also available online
at: https://github.com/enthought/vpsearch.

Thanks for using Enthought open source!

"""

import unittest

from vpsearch._vpsearch import self_aligned_score


class TestSelfAlignedScore(unittest.TestCase):

    def test_self_aligned_score(self):
        # Given
        seq = b'ACGT'
        expected_score = 20

        # When
        seqscore = self_aligned_score(seq, len(seq))

        # Then
        self.assertEqual(expected_score, seqscore)

    def test_self_score_unambiguous_char(self):
        # Given
        seq = b'T'
        expected_score = 5

        # When
        seqscore = self_aligned_score(seq, len(seq))

        # Then
        self.assertEqual(expected_score, seqscore)

    def test_self_score_ambiguous_char(self):
        # Given
        seq = b'Y'
        expected_score = +1

        # When
        seqscore = self_aligned_score(seq, len(seq))

        # Then
        self.assertEqual(expected_score, seqscore)

    def test_self_score_with_ambiguous_seq(self):
        # Given
        seq = b'ACGTN'
        expected_score = 21

        # When
        seqscore = self_aligned_score(seq, len(seq))

        # Then
        self.assertEqual(expected_score, seqscore)


class TestModifiedNuc(unittest.TestCase):

    def test_char_scores(self):
        # Test for the modified nuc44 matrix, which has +1 on the diagonal for
        # ambiguous nucleotides.
        for ch in 'ACGT':
            s = self_aligned_score(ch.encode(), 1)
            self.assertEqual(s, 5)
        for ch in 'SWRYKMBVHDNU':
            s = self_aligned_score(ch.encode(), 1)
            self.assertEqual(s, 1)
