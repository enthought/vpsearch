import os
import sys

from setuptools import find_packages

from distutils.core import setup
from distutils.extension import Extension

import numpy as np
from Cython.Build import cythonize


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


def get_long_description():
    with open("README.md") as fp:
        return fp.read()


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
    version='0.2.0.dev0',
    author='Enthought',
    author_email='info@enthought.com',
    url='https://github.com/enthought/vpsearch',
    description='Global-Global genetic database search.',
    long_description=get_long_description(),
    long_description_content_type='text/markdown',
    classifiers=[
        "Development Status :: 3 - Alpha",
        "Intended Audience :: Science/Research",
        "License :: OSI Approved :: BSD License",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.6",
        "Programming Language :: Python :: 3.7",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Cython",
        "Topic :: Scientific/Engineering",
    ],
    license="BSD",
    platforms=["Linux", "Mac OS-X", "Unix"],
    ext_modules=cythonize([
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
            extra_link_args=CPP_BASE_ARGS + LINK_ARGS,
            depends=[
                'vpsearch/fastqueue.hpp',
                'vpsearch/parasail.pxi',
            ]
        ),
    ]),
    entry_points={
        'console_scripts': [
            'vpsearch=vpsearch._cli:main',
        ],
    },
    install_requires=[
        "click",
        "numpy",
    ],
    packages=find_packages(),
)
