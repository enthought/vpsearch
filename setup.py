import os
import sys

# Monkeypatch distutils.
from setuptools import find_packages  # noqa

from distutils.core import setup
from distutils.extension import Extension

import numpy as np
from Cython.Build import build_ext


def parasail_get_include():
    try:
        return os.environ['PARASAIL_INCLUDE_DIR']
    except KeyError:
        return os.path.join(sys.prefix, "include")


def parasail_get_lib():
    try:
        return os.environ['PARASAIL_LIBRARY_DIR']
    except KeyError:
        return os.path.join(sys.prefix, "lib")


if sys.platform == 'darwin':
    # Use libc++ instead of libstdc++ on Mac OS. The latter has been deprecated
    # since XCode 8 and is removed in XCode 10 (which ships with mac OS
    # Mojave).
    CPP_BASE_ARGS = ['-stdlib=libc++', '-mmacosx-version-min=10.9']
    LINK_ARGS = []
else:
    CPP_BASE_ARGS = []
    # Recent versions of ld will set RUNPATH rather than RPATH, which breaks
    # Cython wrappers that expose functionality from a shared object file.
    LINK_ARGS = ['-Wl,--disable-new-dtags']


setup(
    name='vpsearch',
    version='0.1',
    author='Enthought',
    description='Global-Global genetic database search.',
    ext_modules=[
        Extension(
            'vpsearch._vpsearch',
            sources=['vpsearch/_vpsearch.pyx'],
            include_dirs=[np.get_include(),
                          parasail_get_include(),
                          'vpsearch'],
            library_dirs=[parasail_get_lib()],
            libraries=['parasail'],
            language='c++',
            extra_compile_args=CPP_BASE_ARGS + ['-std=c++11'],
            extra_link_args=CPP_BASE_ARGS + LINK_ARGS),
    ],
    license="Proprietary",
    entry_points={
        'console_scripts': [
            'vpsearch=vpsearch._cli:main',
        ],
    },
    cmdclass=dict(build_ext=build_ext),
)
