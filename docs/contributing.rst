=================================
Reporting issues and contributing
=================================

We welcome bug fixes and improvements to vpsearch, as well as larger contributions. We encourage you to `open an issue <https://github.com/enthought/vpsearch/issues/new>`_ to keep track of bugs, improvements, and so on.

Note that contributing to vpsearch requires adherence to our :ref:`Code of Conduct <coc>`.

Where to start
--------------

If you are new to contributing to open source, please have a look at `this guide <https://opensource.guide/how-to-contribute/>`_ to get involved. We try to follow a process that is similar to most other scientific Python packages.

If you are looking for an issue to work, we recommend having a look at the list of currently open issues. Of course, if you come across a bug or an idea for an improvement during your usage of VPSearch, we'd love to hear about it. In this case, please consider `opening an issue first <https://github.com/enthought/vpsearch/issues/new>`_ first, for further discussion.

How to contribute
-----------------

The following is a whirlwind overview of the contribution process. Not everything is described in detail, but we hope that the process is sufficiently similar to other scientific Python packages. Feel free to open an issue if any of these steps are unclear, or if you require further help!

#. Make sure you have a development environment set up, as described in :ref:`Getting started - from source <installation-development>`. 

#. Create a new Git branch for your fixes.

#. Hack away! Keep in mind that changing the Cython code will require re-compiling the code before any changes are picked up. The compilation step can be re-run using the ``pip install -e . -v`` command that you ran to set up the development environment.

#. Write one or several unit tests to cover the affected areas of the codebase. For a new feature, tests should exercise the new functionality, while for bug fixes, a regression test is appropriate. For the latter, it is a good idea to ensure that the test fails without your fix in place.

#. Once you are happy with your contribution, commit it to your branch and open a Pull Request (PR). 

Once you have an open PR, we will try to review it within a reasonable timeframe. Most of this process will take place over at GitHub (discussion, suggesting changes, and so on), but it may happen that we ask you to make certain changes to the code as well. In that case, just follow the same process as above: commit the changes to your branch, push the changes back to GitHub, and let one of the maintainers know that new changes are available.
