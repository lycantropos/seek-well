seek-well
=========

[![Travis CI](https://travis-ci.org/lycantropos/seek-well.svg?branch=master)](https://travis-ci.org/lycantropos/seek-well)
[![Docker Hub](https://img.shields.io/docker/build/lycantropos/seek-well.svg)](https://hub.docker.com/r/lycantropos/seek-well/builds/)
[![License](https://img.shields.io/github/license/lycantropos/seek-well.svg)](https://github.com/lycantropos/seek-well/blob/master/LICENSE)
[![PyPI](https://badge.fury.io/py/seek-well.svg)](https://badge.fury.io/py/seek-well)

In what follows `python3` is an alias for `python3.6` or any later
version.

Installation
------------

Install the latest `pip` & `setuptools` packages versions

```bash
python3 -m pip install --upgrade pip setuptools
```

### Release

Download and install the latest stable version from `PyPI` repository

```bash
python3 -m pip install --upgrade seek-well
```

### Developer

Download and install the latest version from `GitHub` repository

```bash
git clone https://github.com/lycantropos/seek-well.git
cd seek-well
python3 setup.py install
```

Bumping version
---------------

Install
[bumpversion](https://github.com/peritus/bumpversion#installation).

Choose which version number category to bump following [semver
specification](http://semver.org/).

Test bumping version

```bash
bumpversion --dry-run --verbose $VERSION
```

where `$VERSION` is the target version number category name, possible
values are `patch`/`minor`/`major`.

Bump version

```bash
bumpversion --verbose $VERSION
```

**Note**: to avoid inconsistency between branches and pull requests,
bumping version should be merged into `master` branch as separate pull
request.

Running tests
-------------

Plain

```bash
python3 setup.py test
```

Inside `Docker` container

```bash
docker-compose up
```

Inside `Docker` container with remote debugger

```bash
./set-dockerhost.sh docker-compose up
```

Bash script (e.g. can be used in `Git` hooks)

```bash
./run-tests.sh
```
