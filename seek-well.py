#!/usr/bin/env python3
import logging

import click

__version__ = '0.0.0'

logger = logging.getLogger(__name__)


@click.group()
def main() -> None:
    logging.basicConfig(level=logging.DEBUG)


@main.command()
def run() -> None:
    """
    Orders modules paths by inclusion.
    """
    pass


if __name__ == '__main__':
    main()
