"""
(C) Copyright 2010-2019 Enthought, Inc., Austin, TX
All Rights Reserved.

This software is provided without warranty under the terms of the BSD license
included in LICENSE.txt and may be redistributed only under the conditions
described in the aforementioned license.  The license is also available online
at: https://github.com/enthought/vpsearch.

Thanks for using Enthought open source!

"""

import os
import unittest

from click.testing import CliRunner

from vpsearch._cli import build, query

SIMPLE_DB = """\
>s0
AAAAA
>s1
CCCCC
>s2
GGGGG
>s3
TTTTT
>s4
AACCC
"""

QUERY_EXACT_MATCH = """\
>q0
AAAAA
"""

EXPECTED_OUTPUT_EXACT_MATCH = """\
q0	s0	100.00	5	0	0	1	5	1	5	0	25
q0	s4	40.00	5	0	0	1	5	1	5	0	-2
q0	s2	0.00	5	0	0	1	5	1	5	0	-20
q0	s3	0.00	5	0	0	1	5	1	5	0	-20
"""

QUERY_ALMOST_MATCH = """\
>q1
GGGGT
"""

EXPECTED_OUTPUT_ALMOST = """\
q1	s2	80.00	5	0	0	1	5	1	5	0	16
q1	s0	0.00	5	0	0	1	5	1	5	0	-20
q1	s1	0.00	5	0	0	1	5	1	5	0	-20
q1	s4	0.00	5	0	0	1	5	1	5	0	-20
"""


class TestVpsearch(unittest.TestCase):

    def _write_fasta(self, content, fname):
        with open(fname, 'w') as f:
            f.write(content)

    def test_query(self):
        runner = CliRunner()
        with runner.isolated_filesystem():
            database_fname = 'db.fasta'
            db_dir = os.path.splitext(database_fname)[0]+'.db'
            self._write_fasta(SIMPLE_DB, database_fname)

            # check building the database without errors
            result = runner.invoke(build, [database_fname])

            self.assertIsNone(result.exception)
            self.assertEqual(result.exit_code, 0)

            # test looking up exact query
            query_exact = 'query0.fasta'
            self._write_fasta(QUERY_EXACT_MATCH, query_exact)

            result = runner.invoke(query, [db_dir, query_exact])

            self.assertIsNone(result.exception)
            self.assertEqual(result.exit_code, 0)

            self.assertEqual(EXPECTED_OUTPUT_EXACT_MATCH, result.output)

            # test looking up an almost matching query
            query_almost = 'query1.fasta'
            self._write_fasta(QUERY_ALMOST_MATCH, query_almost)

            result = runner.invoke(query, [db_dir, query_almost])

            self.assertIsNone(result.exception)
            self.assertEqual(result.exit_code, 0)

            self.assertEqual(EXPECTED_OUTPUT_ALMOST, result.output)
