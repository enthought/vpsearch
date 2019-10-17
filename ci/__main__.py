from pathlib import Path
import subprocess
import sys

import click

BUNDLES = {
    "osx-x86_64": "vpsearch_py3.6_osx-x86_64.json",
    "rh6-x86_64": "vpsearch_py3.6_rh6-x86_64.json",
}
DEVENV = "vpsearch"


@click.group()
def cli():
    pass


@cli.command('build-devenv')
def build_devenv():
    platform = _get_platform_tag()

    _install_bundle(BUNDLES[platform], environment=DEVENV)
    _install_package(DEVENV)


@cli.command('run-tests')
def run_tests():
    cmd = ["python", "-m", "unittest", "discover", "-v", "vpsearch"]
    _run_in_env(cmd, environment=DEVENV)


def _get_platform_tag():
    supported = {
        'linux': 'rh6-x86_64',
        'darwin': 'osx-x86_64',
    }
    try:
        return supported[sys.platform]
    except KeyError:
        msg = f"Not a supported platform: {sys.platform}"
        raise click.UsageError(msg) from None


def _install_bundle(fname, environment):
    _run(['edm', 'env', 'import', '-f', fname, '--force', environment])


def _install_package(environment):
    package_dir = Path(__file__).parents[1]
    _run(['pip', 'install', '-e', str(package_dir)])


def _run(cmd, **kwds):
    kwds = {'check': True, **kwds}
    subprocess.run(cmd, **kwds)


def _run_in_env(cmd, environment, **kwds):
    cmd = ['edm', 'run', '-e', environment, '--'] + cmd
    _run(cmd, **kwds)


if __name__ == '__main__':
    cli()
