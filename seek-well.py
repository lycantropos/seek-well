#!/usr/bin/env python3.6
import copy
import json
import logging
import os
import re
from collections import (OrderedDict,
                         namedtuple)
from functools import partial
from itertools import (filterfalse,
                       takewhile)
from shlex import quote
from typing import (Union,
                    Optional,
                    Callable,
                    Iterable,
                    Iterator,
                    Dict,
                    Tuple,
                    Set,
                    List)

import click
import sqlparse
from graphviz import (ENGINES,
                      FORMATS,
                      Digraph)
from sqlparse.keywords import (SQL_REGEX,
                               FLAGS)
from sqlparse.sql import (Token,
                          Identifier,
                          IdentifierList,
                          Parenthesis)
from sqlparse.tokens import (Keyword,
                             Punctuation)

__version__ = '0.0.3'

logger = logging.getLogger(__name__)

# adding PostgreSQL specific keywords
SQL_REGEX.insert(0, (re.compile(r'MATERIALIZED\s+VIEW', FLAGS).match,
                     Keyword))

SCRIPT_FILE_EXTENSION = '.sql'
JSON_FILE_EXTENSION = '.json'
GRAPHVIZ_FILE_EXTENSION = '.gv'

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
ALIAS_KEYWORDS_RE = re.compile(r'^AS$')

MATERIALIZED_VIEW_TYPE = 'MATERIALIZED VIEW'

SQLScript = namedtuple('SQLScript', ['used', 'defined'])
SQLIdentifier = namedtuple('SQLIdentifier', ['type', 'name'])


@click.group()
def main() -> None:
    logging.basicConfig(level=logging.DEBUG)


@main.command()
@click.option('--path', '-p',
              default=os.getcwd(),
              type=click.Path(),
              help='Target scripts directory path.')
@click.option('--initializer-file-name', '-i',
              default=None,
              type=str,
              help='SQL script name for consecutive '
                   'drop and initialization '
                   '(".sql" extension will be added automatically).')
@click.option('--refresher-file-name', '-r',
              default=None,
              type=str,
              help='SQL script name for consecutive '
                   'materialized views refreshing '
                   '(".sql" extension will be added automatically).')
@click.option('--json-file-name', '-j',
              default=None,
              type=str,
              help='JSON output file name '
                   '(".json" extension will be added automatically).')
@click.option('--graphviz-file-name', '-g',
              default=None,
              type=str,
              help='Graphviz output file name '
                   '(".gv" extension will be added automatically).')
@click.option('--graphviz-layout-command', '-l',
              default=None,
              type=click.Choice(ENGINES))
@click.option('--graphviz-rendering-format', '-f',
              default=None,
              type=click.Choice(FORMATS))
def run(path: str,
        initializer_file_name: str,
        refresher_file_name: str,
        json_file_name: str,
        graphviz_file_name: str,
        graphviz_layout_command: str,
        graphviz_rendering_format: str) -> None:
    """
    Orders scripts paths by inclusion.
    """
    path = os.path.abspath(path)
    paths = list(scripts_paths(path))
    scripts_by_paths = dict(parse_scripts(paths))
    defined_names_by_paths = {path: script_defined_names(script)
                              for path, script in scripts_by_paths.items()}
    check_scripts_circular_dependencies(
        scripts_by_paths=scripts_by_paths,
        defined_names_by_paths=defined_names_by_paths)
    update_chained_scripts(
        scripts_by_paths=scripts_by_paths,
        defined_names_by_paths=defined_names_by_paths)
    sorted_scripts_by_paths = OrderedDict(sort_scripts(scripts_by_paths
                                                       .items()))
    if initializer_file_name:
        generate_initializer(file_name=initializer_file_name,
                             scripts_by_paths=sorted_scripts_by_paths)
    if refresher_file_name:
        generate_refresher(file_name=refresher_file_name,
                           scripts_by_paths=sorted_scripts_by_paths)
    if graphviz_file_name:
        export_graphviz(file_name=graphviz_file_name,
                        rendering_format=graphviz_rendering_format,
                        layout_command=graphviz_layout_command,
                        scripts_by_paths=sorted_scripts_by_paths,
                        defined_names_by_paths=defined_names_by_paths)
    if json_file_name:
        export_json(file_name=json_file_name,
                    scripts_by_paths=sorted_scripts_by_paths)


def generate_initializer(*,
                         file_name: str,
                         scripts_by_paths: Dict[str, SQLScript]
                         ) -> None:
    file_name += SCRIPT_FILE_EXTENSION
    with open(file_name, mode='w') as file:
        file.writelines(initializer(scripts_by_paths))


def initializer(scripts_by_paths: Dict[str, SQLScript]) -> Iterable[str]:
    for path in scripts_by_paths:
        yield f'\i {quote(path)}\n'


def generate_refresher(*,
                       file_name: str,
                       scripts_by_paths: Dict[str, SQLScript]
                       ) -> None:
    file_name += SCRIPT_FILE_EXTENSION
    with open(file_name, mode='w') as file:
        file.writelines(refresher(scripts_by_paths))


def refresher(scripts_by_paths: Dict[str, SQLScript]
              ) -> Iterable[str]:
    def is_materialized_view(identifier: SQLIdentifier) -> bool:
        return identifier.type == MATERIALIZED_VIEW_TYPE

    for script in scripts_by_paths.values():
        materialized_view_identifiers = filter(is_materialized_view,
                                               script.defined)
        for identifier in materialized_view_identifiers:
            yield (f'REFRESH {MATERIALIZED_VIEW_TYPE} {identifier.name} '
                   f'WITH DATA;\n')


def export_graphviz(*,
                    file_name: str,
                    rendering_format: str,
                    layout_command: str,
                    scripts_by_paths: Dict[str, SQLScript],
                    defined_names_by_paths: Dict[str, Set[str]]
                    ) -> None:
    dependencies_graph = Digraph(format=rendering_format,
                                 engine=layout_command)
    set_dependencies_graph_nodes(graph=dependencies_graph,
                                 scripts_by_paths=scripts_by_paths,
                                 defined_names_by_paths=defined_names_by_paths)

    source_file_name = file_name + GRAPHVIZ_FILE_EXTENSION
    dependencies_graph.save(filename=source_file_name)
    dependencies_graph.render(filename=file_name,
                              cleanup=True)


def set_dependencies_graph_nodes(*,
                                 graph: Digraph,
                                 scripts_by_paths: Dict[str, SQLScript],
                                 defined_names_by_paths: Dict[str, Set[str]]
                                 ) -> None:
    for path, defined_names in defined_names_by_paths.items():
        graph.node(path, label=', '.join(defined_names))
    for path, script in scripts_by_paths.items():
        dependencies_paths = filter(
            None,
            (name_path(name,
                       defined_names_by_paths=defined_names_by_paths)
             for name in script.used))
        for dependency_path in dependencies_paths:
            graph.edge(dependency_path, path)


def export_json(*,
                file_name: str,
                scripts_by_paths: Dict[str, SQLScript]) -> None:
    file_name += JSON_FILE_EXTENSION
    with open(file_name, mode='w') as file:
        normalized_scripts_by_paths = OrderedDict(normalize(scripts_by_paths
                                                            .items()))
        json.dump(obj=normalized_scripts_by_paths,
                  fp=file,
                  indent=True)


def normalize(paths_scripts: Iterable[Tuple[str, SQLScript]]
              ) -> Iterable[Tuple[str, OrderedDict]]:
    for path, script in paths_scripts:
        defined_identifiers = list(script.defined)
        defined_identifiers.sort()
        used_names = list(script.used)
        used_names.sort()
        script = OrderedDict(defined=defined_identifiers,
                             used=used_names)
        yield path, script


def sort_scripts(paths_scripts: Iterable[Tuple[str, SQLScript]]
                 ) -> List[Tuple[str, SQLScript]]:
    res = list()
    for path, script in paths_scripts:
        index_by_defined = min(
            (index
             for index, (_, other_script) in enumerate(
                res,
                # insertion should be before script
                # in which one of current script's defined identifiers is used
                start=0)
             if any(identifier.name in other_script.used
                    for identifier in script.defined)),
            default=0)
        index_by_used = max(
            (index
             for index, (_, other_script) in enumerate(
                res,
                # insertion should be after script
                # in which one of current script's used identifiers is defined
                start=1)
             if any(used_name in script_defined_names(other_script)
                    for used_name in script.used)),
            default=0)
        index = max(index_by_defined, index_by_used)
        res.insert(index, (path, script))
    return res


def check_scripts_circular_dependencies(
        *,
        scripts_by_paths: Dict[str, SQLScript],
        defined_names_by_paths: Dict[str, Set[str]]) -> None:
    for script in scripts_by_paths.values():
        check_script_circular_dependencies(
            script=script,
            defined_names=set(),
            scripts_by_paths=scripts_by_paths,
            defined_names_by_paths=defined_names_by_paths)


def check_script_circular_dependencies(
        *,
        script: SQLScript,
        defined_names: Set[str],
        scripts_by_paths: Dict[str, SQLScript],
        defined_names_by_paths: Dict[str, Set[str]]) -> None:
    # TODO: find out why augmented assignment doesn't work properly sometimes
    defined_names = defined_names | script_defined_names(script)
    for name in script.used:
        dependency_path = name_path(
            name,
            defined_names_by_paths=defined_names_by_paths)
        try:
            dependency = scripts_by_paths[dependency_path]
        except KeyError:
            continue
        try:
            cyclic_name = next(name
                               for name in dependency.used
                               if name in defined_names)
            cyclic_name_path = name_path(
                cyclic_name,
                defined_names_by_paths=defined_names_by_paths)
            err_msg = ('Cyclic usage found: '
                       f'name "{cyclic_name}" '
                       'is defined in script '
                       f'"{cyclic_name_path}" '
                       'which is one of '
                       f'located at "{dependency_path}" '
                       'script users.')
            raise RecursionError(err_msg)
        except StopIteration:
            check_script_circular_dependencies(
                script=dependency,
                defined_names=defined_names,
                scripts_by_paths=scripts_by_paths,
                defined_names_by_paths=defined_names_by_paths)


def script_defined_names(script: SQLScript) -> Set[str]:
    return {identifier.name for identifier in script.defined}


def update_chained_scripts(*,
                           scripts_by_paths: Dict[str, SQLScript],
                           defined_names_by_paths: Dict[str, Set[str]]
                           ) -> None:
    scripts_by_paths_copy = copy.deepcopy(scripts_by_paths)

    for path, script_copy in scripts_by_paths_copy.items():
        unprocessed_dependencies_names = copy.deepcopy(script_copy.used)
        try:
            while True:
                name = unprocessed_dependencies_names.pop()
                dependency_path = name_path(
                    name,
                    defined_names_by_paths=defined_names_by_paths)
                try:
                    dependency = scripts_by_paths[dependency_path]
                except KeyError:
                    continue

                unprocessed_dependencies_names |= dependency.used

                script = scripts_by_paths[path]
                used = (script.used
                        | dependency.used
                        | defined_names_by_paths[dependency_path])
                scripts_by_paths[path] = script._replace(used=used)
        except KeyError:
            continue


def name_path(name: str,
              *,
              defined_names_by_paths: Dict[str, Set[str]]
              ) -> Optional[str]:
    paths = [path
             for path, defined_names in defined_names_by_paths.items()
             if name in defined_names]
    try:
        path, = paths
        return path
    except ValueError as err:
        if paths:
            paths_str = ', '.join(paths)
            err_msg = ('Requested module name is ambiguous: '
                       f'found {len(paths)} appearances '
                       f'of name "{name}" '
                       'in scripts definitions within '
                       f'files located at {paths_str}.')
            raise ValueError(err_msg) from err
        warn_msg = ('Requested identifier is not found: '
                    'no appearance '
                    f'of name "{name}" '
                    'in scripts definitions.')
        logger.warning(warn_msg)
        return None


def scripts_paths(path: str) -> Iterable[str]:
    for root, directories, files_names in os.walk(path):
        for file_name in files_names:
            _, extension = os.path.splitext(file_name)
            if extension != SCRIPT_FILE_EXTENSION:
                continue
            yield os.path.join(root, file_name)


def parse_scripts(paths: Iterable[str]
                  ) -> Iterable[Tuple[str, SQLScript]]:
    for path, raw_script_str in read_scripts(paths):
        used_names = (set(script_used_names(raw_script_str))
                      - set(script_aliases(raw_script_str)))
        defined_identifiers = set(script_defined_identifiers(raw_script_str))
        yield path, SQLScript(defined=defined_identifiers,
                              used=used_names)


def read_scripts(paths: Iterable[str]) -> Iterable[Tuple[str, str]]:
    for path in paths:
        with open(path) as raw_script:
            raw_script_str = raw_script.read()
        yield path, raw_script_str


def filtered_script_names_or_identifiers(
        raw_script: str,
        *,
        names_or_identifiers_filter: Callable[[Token], Iterable[str]]
) -> Iterable[Token]:
    statements = sqlparse.parsestream(raw_script)
    for statement in statements:
        yield from names_or_identifiers_filter(statement)


def token_used_names(token: Token) -> Iterable[str]:
    try:
        tokens = filtered_tokens(token.tokens)
    except AttributeError:
        return
    for token in tokens:
        if is_identifier(token) and is_used_identifier(token):
            yield token.normalized
            continue
        yield from token_used_names(token)


def token_defined_identifiers(token: Token) -> Iterable[SQLIdentifier]:
    try:
        tokens = filtered_tokens(token.tokens)
    except AttributeError:
        return
    for token in tokens:
        if is_identifier(token) and is_defined_identifier(token):
            older_siblings = older_tokens(token)
            older_keywords = list(filter(is_keyword, older_siblings))
            identifier_type = older_keywords[1].normalized
            yield SQLIdentifier(type=identifier_type,
                                name=token.normalized)
            continue
        yield from token_defined_identifiers(token)


def token_aliases(token: Token) -> Iterable[str]:
    try:
        tokens = filtered_tokens(token.tokens)
    except AttributeError:
        return
    for token in tokens:
        if is_identifier(token) and is_alias(token):
            yield token.normalized
        yield from token_aliases(token)


script_used_names = partial(
    filtered_script_names_or_identifiers,
    names_or_identifiers_filter=token_used_names)

script_defined_identifiers = partial(
    filtered_script_names_or_identifiers,
    names_or_identifiers_filter=token_defined_identifiers)

script_aliases = partial(
    filtered_script_names_or_identifiers,
    names_or_identifiers_filter=token_aliases)


def is_used_identifier(token: Union[Identifier, IdentifierList]
                       ) -> bool:
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
    older_siblings = list(older_tokens(token))
    try:
        nearest_older_sibling = older_siblings[-1]
    except IndexError:
        return False
    nearest_older_sibling_str = (nearest_older_sibling
                                 .normalized.upper())
    return USAGE_KEYWORDS_RE.match(nearest_older_sibling_str) is not None


def is_defined_identifier(identifier: Identifier) -> bool:
    parent_keywords = filter(is_keyword, identifier.parent.tokens)
    try:
        first_parent_keyword = next(parent_keywords)
    except StopIteration:
        return False
    first_parent_keyword_str = (first_parent_keyword
                                .normalized.upper())
    return DEFINITION_KEYWORDS_RE.match(first_parent_keyword_str) is not None


def is_alias(token: Union[Identifier, IdentifierList]
             ) -> bool:
    children = child_tokens(token)
    try:
        nearest_child = next(children)
    except StopIteration:
        return False
    nearest_child_str = (nearest_child
                         .normalized.upper())
    return ALIAS_KEYWORDS_RE.match(nearest_child_str) is not None


def older_tokens(token: Token) -> Iterable[Token]:
    def older(sibling: Token) -> bool:
        # we assume that siblings are ordered
        return sibling is not token

    siblings = filtered_tokens(token.parent.tokens)
    yield from takewhile(older, siblings)


def child_tokens(token: Token) -> Iterator[Token]:
    children = filtered_tokens(token.tokens)
    next(children)
    yield from children


def filtered_tokens(tokens: Iterable[Token]) -> Iterator[Token]:
    yield from filterfalse(is_filler, tokens)


def is_identifier(token: Token) -> bool:
    return isinstance(token, Identifier)


def is_keyword(token: Token) -> bool:
    return token.is_keyword


def is_filler(token: Token) -> bool:
    return token.is_whitespace or token.ttype is Punctuation


if __name__ == '__main__':
    main()
