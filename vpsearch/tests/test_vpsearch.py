import unittest

from microbiome.vpsearch._vpsearch import score

class TestCase(unittest.TestCase):

    def test_score(self):
        # Given
        seq = b'ACGT'
        expected_score = 20

        # When
        seqscore = score(seq)

        # Then
        self.assertEqual(expected_score, seqscore)

    def test_score_unambiguous_char(self):
        # Given
        seq = b'T'
        expected_score = 5

        # When
        seqscore = score(seq)

        # Then
        self.assertEqual(expected_score, seqscore)

    def test_score_ambiguous_char(self):
        # Given
        seq = b'Y'
        expected_score = -1

        # When
        seqscore = score(seq)

        # Then
        self.assertEqual(expected_score, seqscore)

    def test_score_with_ambiguous_seq(self):
        # Given
        seq = b'ACGTN'
        expected_score = 19

        # When
        seqscore = score(seq)

        # Then
        self.assertEqual(expected_score, seqscore)
