#!/usr/bin/env python3
import json
import logging
import os
import re
from collections import (OrderedDict,
                         namedtuple)
from functools import partial
from itertools import filterfalse
from typing import (Callable,
                    Iterable,
                    Iterator,
                    IO,
                    Dict,
                    Tuple)

import click
import sqlparse
from sqlparse.keywords import KEYWORDS
from sqlparse.sql import (Token,
                          Identifier,
                          IdentifierList,
                          Parenthesis)
from sqlparse.tokens import (Punctuation,
                             Keyword)

__version__ = '0.0.0'

logger = logging.getLogger(__name__)

# adding PostgreSQL specific keywords
KEYWORDS.update({'MATERIALIZED': Keyword,
                 'WINDOW': Keyword})

SQL_SCRIPTS_EXTENSIONS = {'.sql'}
OUTPUT_FILE_EXTENSION = '.json'

DEFINITION_KEYWORDS_RE = re.compile(r'^CREATE(\s+OR\s+REPLACE)?$')
USAGE_KEYWORDS_RE = re.compile(
    r'^('
    r'((CROSS\s+)'
    r'|'
    r'((NATURAL\s+)?'
    r'((INNER\s+)?'
    r'|'
    r'((LEFT\s+|RIGHT\s+|FULL\s+)(OUTER\s+)?))))?'
    r'JOIN'
    r'|'
    r'FROM'
    r')$')

SQLScript = namedtuple('SQLScript', ['used', 'defined'])


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
        defined_identifiers = list(script.defined)
        defined_identifiers.sort()
        used_identifiers = list(script.used)
        used_identifiers.sort()
        script = OrderedDict(defined=defined_identifiers,
                             used=used_identifiers)
        yield script_path, script


def parse_scripts(paths: Iterable[str]
                  ) -> Iterable[Tuple[str, SQLScript]]:
    for script_path, raw_script_str in read_scripts(paths):
        script = SQLScript(
            defined=set(script_defined_identifiers(raw_script_str)),
            used=set(script_used_identifiers(raw_script_str)))
        yield script_path, script


def read_scripts(paths: Iterable[str]) -> Iterable[Tuple[str, str]]:
    for script_path in paths:
        with open(script_path) as raw_script:
            raw_script_str = raw_script.read()
        yield script_path, raw_script_str


def script_used_identifiers(raw_script: str
                            ) -> Iterable[Token]:
    statements = sqlparse.parsestream(raw_script)
    for statement in statements:
        yield from token_used_identifiers(statement)


def script_defined_identifiers(raw_script: str
                               ) -> Iterable[Token]:
    statements = sqlparse.parsestream(raw_script)
    for statement in statements:
        yield from token_defined_identifiers(statement)


def scripts_paths(path: str) -> Iterable[str]:
    for root, directories, files_names in os.walk(path):
        for file_name in files_names:
            _, extension = os.path.splitext(file_name)
            if extension not in SQL_SCRIPTS_EXTENSIONS:
                continue
            yield os.path.join(root, file_name)


def is_used_identifier(token: Token) -> bool:
    try:
        tokens = list(filtered_tokens(token.tokens))
    except AttributeError:
        return False
    else:
        if isinstance(tokens[0], Parenthesis):
            # look further
            return False

    parent = token.parent
    if isinstance(parent, IdentifierList):
        return is_used_identifier(parent)
    siblings = list(filtered_tokens(parent.tokens))
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
    return USAGE_KEYWORDS_RE.match(nearest_older_token_str) is not None


def is_defined_identifier(token: Token) -> bool:
    parent_keyword_tokens = get_keyword_tokens(token.parent)
    try:
        first_parent_token = next(parent_keyword_tokens)
    except StopIteration:
        return False
    first_parent_token_str = (first_parent_token
                              .normalized.upper())
    return DEFINITION_KEYWORDS_RE.match(first_parent_token_str) is not None


def filtered_token_identifiers(token: Token,
                               *,
                               identifiers_filter: Callable[[Token], bool]
                               ) -> Iterable[str]:
    try:
        tokens = filtered_tokens(token.tokens)
    except AttributeError:
        return
    for token in tokens:
        if is_identifier(token) and identifiers_filter(token):
            yield token.normalized
            continue
        yield from token_used_identifiers(token)


def is_identifier(token: Token) -> bool:
    return isinstance(token, Identifier)


token_used_identifiers = partial(filtered_token_identifiers,
                                 identifiers_filter=is_used_identifier)
token_defined_identifiers = partial(filtered_token_identifiers,
                                    identifiers_filter=is_defined_identifier)


def filtered_tokens(tokens: Iterable[Token]) -> Iterable[Token]:
    return filterfalse(is_filler, tokens)


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
