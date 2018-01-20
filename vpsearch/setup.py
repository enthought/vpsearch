import os

# Monkeypatch distutils.
from setuptools import find_packages

from distutils.core import setup
from distutils.extension import Extension

import numpy as np
from Cython.Distutils import build_ext


# NOTE: Set these environment variables appropriately.
parasail_include_dir = os.environ.get(
    'PARASAIL_INCLUDE_DIR', '/usr/local/include'
)
parasail_library_dir = os.environ.get(
    'PARASAIL_LIBRARY_DIR', '/usr/local/lib'
)

setup(
    name='vpsearch',
    version='0.1',
    author='Enthought',
    description='Global-Global genetic database search.',
    ext_modules=[
        Extension('vpsearch._vpsearch',
                  sources=['vpsearch/_vpsearch.pyx'],
                  include_dirs=[np.get_include(), parasail_include_dir, 'vpsearch'],
                  library_dirs=[parasail_library_dir],
                  libraries=['parasail'],
                  language='c++',
                  extra_compile_args=['-std=c++11'],
        ),
    ],
    license="Proprietary",
    entry_points={
        'console_scripts': [
            'vpsearch=vpsearch._cli:main',
        ],
    },
    cmdclass=dict(build_ext=build_ext),
)
