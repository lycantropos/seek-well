#!/usr/bin/env python3
import copy
import json
import logging
import os
import re
from collections import (OrderedDict,
                         namedtuple)
from functools import partial
from itertools import filterfalse
from typing import (Union,
                    Optional,
                    Callable,
                    Iterable,
                    IO,
                    Dict,
                    Tuple, Set)

import click
import sqlparse
from sqlparse.keywords import KEYWORDS
from sqlparse.sql import (Token,
                          Identifier,
                          IdentifierList,
                          Parenthesis)
from sqlparse.tokens import (Punctuation,
                             Keyword)

__version__ = '0.0.1'

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
    check_scripts_circular_dependencies(scripts_by_paths)
    update_chained_scripts(scripts_by_paths)
    if output_file_name:
        output_file_name += OUTPUT_FILE_EXTENSION
        with open(output_file_name, mode='w') as output_file:
            export(scripts_by_paths=scripts_by_paths,
                   stream=output_file)


def check_scripts_circular_dependencies(scripts_by_paths: Dict[str, SQLScript]
                                        ) -> None:
    for script in scripts_by_paths.values():
        check_script_circular_dependencies(script=script,
                                           defined_identifiers=set(),
                                           scripts_by_paths=scripts_by_paths)


def check_script_circular_dependencies(*,
                                       script: SQLScript,
                                       defined_identifiers: Set[str],
                                       scripts_by_paths: Dict[str, SQLScript]
                                       ) -> None:
    defined_identifiers = defined_identifiers | script.defined
    for identifier in script.used:
        dependency_path = identifier_path(identifier,
                                          scripts_by_paths=scripts_by_paths)
        try:
            dependency = scripts_by_paths[dependency_path]
        except KeyError:
            continue
        try:
            cyclic_identifier = next(identifier
                                     for identifier in dependency.used
                                     if identifier in defined_identifiers)
            cyclic_identifier_path = identifier_path(cyclic_identifier,
                                                     scripts_by_paths=scripts_by_paths)
            err_msg = ('Cyclic usage found: '
                       f'identifier "{cyclic_identifier}" '
                       'is defined in script '
                       f'"{cyclic_identifier_path}" '
                       'which is one of '
                       f'located at "{dependency_path}" '
                       'script users.')
            raise RecursionError(err_msg)
        except StopIteration:
            check_script_circular_dependencies(script=dependency,
                                               defined_identifiers=defined_identifiers,
                                               scripts_by_paths=scripts_by_paths)


def update_chained_scripts(scripts_by_paths: Dict[str, SQLScript]
                           ) -> None:
    scripts_by_paths_copy = copy.deepcopy(
        scripts_by_paths)

    for path, script_copy in scripts_by_paths_copy.items():
        unprocessed_identifiers = copy.deepcopy(script_copy.used)
        try:
            while True:
                identifier = unprocessed_identifiers.pop()
                extension_path = identifier_path(identifier,
                                                 scripts_by_paths=scripts_by_paths_copy)
                try:
                    extension = scripts_by_paths[extension_path]
                except KeyError:
                    continue

                unprocessed_identifiers |= extension.used

                script = scripts_by_paths[path]
                used = (
                    script.used
                    | extension.used
                    | extension.defined)
                scripts_by_paths[path] = script._replace(used=used)
        except KeyError:
            continue


def identifier_path(identifier: str,
                    *,
                    scripts_by_paths: Dict[str, SQLScript]
                    ) -> Optional[str]:
    paths = [path
             for path, script in scripts_by_paths.items()
             if identifier in script.defined]
    try:
        path, = paths
        return path
    except ValueError as err:
        if paths:
            paths_str = ', '.join(paths)
            err_msg = ('Requested module name is ambiguous: '
                       f'found {len(paths)} appearances '
                       f'of identifier "{identifier}" '
                       'in scripts definitions within '
                       f'files located at {paths_str}.')
            raise ValueError(err_msg) from err
        warn_msg = ('Requested identifier is not found: '
                    'no appearance '
                    f'of identifier "{identifier}" '
                    'in scripts definitions.')
        logger.warning(warn_msg)
        return None


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


def scripts_paths(path: str) -> Iterable[str]:
    for root, directories, files_names in os.walk(path):
        for file_name in files_names:
            _, extension = os.path.splitext(file_name)
            if extension not in SQL_SCRIPTS_EXTENSIONS:
                continue
            yield os.path.join(root, file_name)


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


def filtered_script_identifiers(
        raw_script: str,
        *,
        filtered_statement_identifiers: Callable[[Token], Iterable[str]]
) -> Iterable[Token]:
    statements = sqlparse.parsestream(raw_script)
    for statement in statements:
        yield from filtered_statement_identifiers(statement)


def is_used_identifier(identifier: Union[Identifier,
                                         IdentifierList]
                       ) -> bool:
    try:
        tokens = list(filtered_tokens(identifier.tokens))
    except AttributeError:
        return False
    else:
        if isinstance(tokens[0], Parenthesis):
            # look further
            return False

    parent = identifier.parent
    if isinstance(parent, IdentifierList):
        return is_used_identifier(parent)
    siblings = list(filtered_tokens(parent.tokens))
    token_index = next(index
                       for index, sibling in enumerate(siblings)
                       if sibling is identifier)
    older_tokens = siblings[:token_index]
    try:
        nearest_older_token = older_tokens[-1]
    except IndexError:
        return False
    nearest_older_token_str = (nearest_older_token
                               .normalized.upper())
    return USAGE_KEYWORDS_RE.match(nearest_older_token_str) is not None


def is_defined_identifier(identifier: Identifier) -> bool:
    parent_keywords = (token
                       for token in identifier.parent.tokens
                       if token.is_keyword)
    try:
        first_parent_keyword = next(parent_keywords)
    except StopIteration:
        return False
    first_parent_keyword_str = (first_parent_keyword
                                .normalized.upper())
    return DEFINITION_KEYWORDS_RE.match(first_parent_keyword_str) is not None


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


token_used_identifiers = partial(filtered_token_identifiers,
                                 identifiers_filter=is_used_identifier)
token_defined_identifiers = partial(filtered_token_identifiers,
                                    identifiers_filter=is_defined_identifier)

script_used_identifiers = partial(
    filtered_script_identifiers,
    filtered_statement_identifiers=token_used_identifiers)
script_defined_identifiers = partial(
    filtered_script_identifiers,
    filtered_statement_identifiers=token_defined_identifiers)


def filtered_tokens(tokens: Iterable[Token]) -> Iterable[Token]:
    return filterfalse(is_filler, tokens)


def is_identifier(token: Token) -> bool:
    return isinstance(token, Identifier)


def is_filler(token: Token) -> bool:
    return is_whitespace(token) or is_punctuation(token)


def is_whitespace(token: Token) -> bool:
    return token.is_whitespace


def is_punctuation(token: Token) -> bool:
    return token.ttype is Punctuation


if __name__ == '__main__':
    main()
