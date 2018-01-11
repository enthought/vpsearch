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
def query(database, query, number):
    """ Query a built database for sequences.
    """
    seqs = [(s[0][1], s[1]) for s in SeqDB(query)]
    tree = LinearVPTree.fromdir(database)
    for qid, q in seqs:
        for mrec in tree.get_nearest_neighbors(q, number):
            click.echo(u'{0}\t{1}'.format(qid.decode(), mrec))


if __name__ == '__main__':
    main()
