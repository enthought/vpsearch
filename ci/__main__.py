import os
from pathlib import Path
import subprocess
import sys

import click

BUNDLES = {
    "osx-x86_64": "vpsearch_py3.8_osx-x86_64.json",
    "rh7-x86_64": "vpsearch_py3.8_rh7-x86_64.json",
}
DEVENV = "vpsearch"

DEPENDENCIES = [
    "click",
    "cython",
    "numpy",
    "parasail",
    "pip",
    "setuptools"
]

PYTHON_VERSION = "3.8"


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


@cli.command(name='regenerate-bundles')
def regenerate_bundles():
    for platform, bundle_fname in BUNDLES.items():
        cmd = [
            "edm",
            "bundle",
            "generate",
            "--version", PYTHON_VERSION,
            "--platform", platform,
            "--bundle-format", "2.0",
            "--output-file", bundle_fname,
        ] + DEPENDENCIES
        _run(cmd)


def _get_platform_tag():
    supported = {
        'linux': 'rh7-x86_64',
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
    _run_in_env(['pip', 'install', '-e', str(package_dir)], environment)


def _run(cmd, **kwds):
    kwds = {'check': True, **kwds}
    click.secho(' '.join(cmd), fg='green')
    subprocess.run(cmd, **kwds)


def _run_in_env(cmd, environment, **kwds):
    cmd = ['edm', 'run', '-e', environment, '--'] + cmd
    _run(cmd, **kwds)


if __name__ == '__main__':
    cli()
