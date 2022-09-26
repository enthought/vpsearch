===============
Building wheels
===============

Wheels for this package can be built in a platform-independent way using
`cibuildwheel <https://cibuildwheel.readthedocs.io/en/stable/>`_, running under
GitHub actions. As an administrator, you can start a workflow to build wheels
by selecting the "Build wheels" action from the GitHub actions menu, and
clicking the "Run workflow" button. When the workflow completes, wheels for
Linux and macOS will be available as a zipped artifact.

It is possible to run cibuildwheels locally, but only to build wheels for
Linux. In a clean Python environment, run ``pip install cibuildwheel`` to install
the tool, followed by::

    CIBW_BUILD_VERBOSITY=1 \
    CIBW_BUILD=cp38-manylinux_x86_64 \
    python -m cibuildwheel --output-dir wheelhouse --platform linux

to build Python 3.8 wheels for Linux. By varying the build tag, wheels for
other Python versions can be built. 
