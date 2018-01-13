import os

from setuptools import setup

import scripts

project_base_url = 'https://github.com/lycantropos/seek-well/'
setup(name='seek-well',
      scripts=[os.path.join('scripts', 'seek-well.py')],
      version=scripts.__version__,
      description=scripts.__doc__,
      long_description=open('README.rst').read(),
      author='Azat Ibrakov',
      author_email='azatibrakov@gmail.com',
      url=project_base_url,
      download_url=project_base_url + 'archive/master.zip',
      keywords=['sql'],
      install_requires=[
          'sqlparse>=0.2.4',  # parsing SQL statements
          'graphviz>=0.8.2',
          'click>=6.7',  # parsing command-line arguments
      ])
