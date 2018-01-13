import os

from setuptools import setup

project_base_url = 'https://github.com/lycantropos/seek-well/'
setup(name='seek-well',
      scripts=[os.path.join('scripts', 'seek-well')],
      version='0.2.1',
      description='Hierarchical ordering "SQL" scripts for correct execution.',
      long_description=open('README.md').read(),
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
