"""
(C) Copyright 2010-2019 Enthought, Inc., Austin, TX
All Rights Reserved.

This software is provided without warranty under the terms of the BSD license
included in LICENSE.txt and may be redistributed only under the conditions
described in the aforementioned license.  The license is also available online
at: https://github.com/enthought/vpsearch.

Thanks for using Enthought open source!

"""

from concurrent.futures import ThreadPoolExecutor
from itertools import repeat
import os
import shutil

import click

from ._vpsearch import SeqDB, VPTree, LinearVPTree


@click.group()
def main():
    pass


@main.command()
@click.argument('sequences')
@click.option('-o', '--output')
@click.option('-f', '--force', is_flag=True)
def build(sequences, output, force):
    """ Build a database of sequences.
    """
    if output is None:
        output = os.path.splitext(sequences)[0] + '.db'
    if os.path.exists(output):
        msg = u"Are you sure you want to overwrite {}?".format(output)
        if force or click.confirm(msg):
            if os.path.isdir(output):
                shutil.rmtree(output)
            else:
                os.unlink(output)
    os.makedirs(output)
    dest_seqs = os.path.join(output, 'sequences.fa')
    shutil.copyfile(sequences, dest_seqs)
    db = SeqDB(dest_seqs)
    seqs = list(db)
    click.echo(u'Building for {} sequences...'.format(len(seqs)), nl=False)
    tree = VPTree.build(seqs)
    click.echo(u'done.')
    click.echo(u'Linearizing...', nl=False)
    linear_tree = LinearVPTree.fromtree(db, tree)
    click.echo(u'done.')
    fn = os.path.join(output, 'indices.npz')
    linear_tree.save(fn)
    click.echo(u'Database created in {}'.format(output))


@main.command()
@click.argument('database')
@click.argument('query')
@click.option('-n', '--number', default=4)
@click.option('-j', '--num-threads', default=1,
              help=("Number of threads to use for parallel lookup. "
                    "The default is to use 1 thread, i.e. to do the "
                    "lookup serially."))
def query(database, query, number, num_threads):
    """ Query a built database for sequences.
    """
    qids = []
    qs = []
    for s in SeqDB(query):
        qids.append(s[0][1].decode())
        qs.append(s[1])

    tree = LinearVPTree.fromdir(database)
    if num_threads <= 1:
        for qid, q in zip(qids, qs):
            for mrec in tree.get_nearest_neighbors(q, number):
                click.echo(u'{0}\t{1}'.format(qid, mrec))
    else:
        with ThreadPoolExecutor(max_workers=num_threads) as executor:
            mrecs_all = executor.map(
                tree.get_nearest_neighbors, qs, repeat(number)
            )
            for qid, mrecs in zip(qids, mrecs_all):
                for mrec in mrecs:
                    click.echo(u'{0}\t{1}'.format(qid, mrec))


if __name__ == '__main__':
    main()
