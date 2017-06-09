#!/usr/bin/env python3
import json
import logging
import os
from collections import OrderedDict, namedtuple
from itertools import filterfalse
from typing import (Iterable,
                    Iterator, Tuple, Dict, IO)

import click
import sqlparse
from sqlparse.sql import (Token,
                          Identifier)
from sqlparse.tokens import Punctuation

__version__ = '0.0.0'

logger = logging.getLogger(__name__)

SQL_SCRIPTS_EXTENSIONS = {'.sql'}
EXTENDED_KEYWORDS = {'MATERIALIZED'}
DEFINITION_KEYWORDS = {'CREATE', 'CREATE OR REPLACE'}
USAGE_KEYWORDS = {'FROM', 'JOIN'}

SQLScript = namedtuple('SQLScript', ['used', 'defined'])
OUTPUT_FILE_EXTENSION = '.json'


@click.group()
def main() -> None:
    logging.basicConfig(level=logging.DEBUG)


@main.command()
@click.option('--path', '-p',
              default=os.getcwd(),
              type=click.Path(),
              help='Target scripts directory path.')
@click.option('--output-file-name', '-o',
              default=None,
              type=str,
              help='File name to save modules relations to '
                   '(".json" extension will be added).')
def run(path: str, output_file_name: str) -> None:
    """
    Orders modules paths by inclusion.
    """
    path = os.path.abspath(path)
    paths = list(scripts_paths(path))
    scripts_by_paths = dict(parse_scripts(paths))
    if output_file_name:
        output_file_name += OUTPUT_FILE_EXTENSION
        with open(output_file_name, mode='w') as output_file:
            export(scripts_by_paths=scripts_by_paths,
                   stream=output_file)


def export(*,
           scripts_by_paths: Dict[str, SQLScript],
           stream: IO[str]) -> None:
    normalized_scripts_by_paths = OrderedDict(normalize(scripts_by_paths))
    json.dump(obj=normalized_scripts_by_paths,
              fp=stream,
              indent=True)


def normalize(scripts_by_paths: Dict[str, SQLScript]
              ) -> Iterable[Tuple[str, OrderedDict]]:
    for script_path, script in scripts_by_paths.items():
        script = OrderedDict(defined=[token.normalized
                                      for token in script.defined],
                             used=[token.normalized
                                   for token in script.used])
        yield script_path, script


def parse_scripts(paths: Iterable[str]
                  ) -> Iterable[Tuple[str, SQLScript]]:
    for script_path, raw_script_str in read_scripts(paths):
        script = SQLScript(defined=list(script_defined_identifiers(raw_script_str)),
                           used=list(script_used_identifiers(raw_script_str)))
        yield script_path, script


def read_scripts(scripts_paths):
    for script_path in scripts_paths:
        with open(script_path) as raw_script:
            raw_script_str = raw_script.read()
        yield script_path, raw_script_str


def script_used_identifiers(raw_script: Iterable[str]
                            ) -> Iterable[Token]:
    statements = sqlparse.parsestream(raw_script)
    for statement in statements:
        yield from token_used_identifiers(statement)


def script_defined_identifiers(raw_script: Iterable[str]
                               ) -> Iterable[Token]:
    statements = sqlparse.parsestream(raw_script)
    for statement in statements:
        yield from token_defined_identifiers(statement)


def token_used_identifiers(token: Token) -> Iterable[Token]:
    try:
        tokens = filtered_tokens(token)
    except AttributeError:
        return
    for token in tokens:
        if is_identifier(token) and is_used_identifier(token):
            yield token
            continue
        yield from token_used_identifiers(token)


def token_defined_identifiers(token: Token
                              ) -> Iterable[Token]:
    try:
        tokens = filtered_tokens(token)
    except AttributeError:
        return
    for token in tokens:
        if is_identifier(token):
            if is_defined_identifier(token):
                yield token
        else:
            yield from token_defined_identifiers(token)


def scripts_paths(path: str) -> Iterable[str]:
    for root, directories, files_names in os.walk(path):
        for file_name in files_names:
            _, extension = os.path.splitext(file_name)
            if extension not in SQL_SCRIPTS_EXTENSIONS:
                continue
            yield os.path.join(root, file_name)


def is_identifier(token: Token) -> bool:
    return (isinstance(token, Identifier) and
            token.normalized.upper() not in EXTENDED_KEYWORDS)


def is_used_identifier(token: Token) -> bool:
    try:
        tokens = token.tokens
        if len(tokens) > 1:
            return False
    except AttributeError:
        return False

    parent = token.parent
    try:
        siblings = list(filtered_tokens(parent))
    except AttributeError:
        return False
    token_index = next(index
                       for index, sibling in enumerate(siblings)
                       if sibling is token)
    older_tokens = siblings[:token_index]
    try:
        nearest_older_token = older_tokens[-1]
    except IndexError:
        return False
    nearest_older_token_str = (nearest_older_token
                               .normalized.upper())
    return nearest_older_token_str in USAGE_KEYWORDS


def is_defined_identifier(token: Token) -> bool:
    parent_keyword_tokens = get_keyword_tokens(token.parent)
    try:
        first_parent_token = next(parent_keyword_tokens)
    except StopIteration:
        return False
    first_parent_token_str = (first_parent_token
                              .normalized.upper())
    return first_parent_token_str in DEFINITION_KEYWORDS


def filtered_tokens(token: Token) -> Iterable[Token]:
    return filterfalse(is_filler, token.tokens)


def is_filler(token: Token) -> bool:
    return is_whitespace(token) or is_punctuation(token)


def is_whitespace(token: Token) -> bool:
    return token.is_whitespace


def is_punctuation(token: Token) -> bool:
    return token.ttype is Punctuation


def get_keyword_tokens(token: Token) -> Iterator[Token]:
    try:
        tokens = token.tokens
    except AttributeError:
        return
    for token in tokens:
        if token.is_keyword:
            yield token


if __name__ == '__main__':
    main()
