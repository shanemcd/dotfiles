#!/usr/bin/env python3
"""Parse a Google Docs JSON export and display the document structure with indices.

Usage:
    python3 doc-structure.py <doc-json-file> [--tables] [--find TEXT]

Examples:
    # Show full document structure (paragraphs with indices and styles)
    python3 doc-structure.py /tmp/doc.json

    # Show only table contents
    python3 doc-structure.py /tmp/doc.json --tables

    # Find specific text and show its index range
    python3 doc-structure.py /tmp/doc.json --find "AAP-76807"
"""
import json
import sys
import argparse


def show_paragraphs(elements, prefix=""):
    for elem in elements:
        if 'paragraph' in elem:
            p = elem['paragraph']
            text = ''.join([e.get('textRun', {}).get('content', '') for e in p.get('elements', [])])
            style = p.get('paragraphStyle', {}).get('namedStyleType', '')
            start = elem.get('startIndex', '')
            end = elem.get('endIndex', '')
            if text.strip():
                print(f'{prefix}[{start}-{end}] ({style}) {text.strip()[:150]}')
        if 'table' in elem:
            ts = elem.get('startIndex', '')
            te = elem.get('endIndex', '')
            print(f'{prefix}=== TABLE [{ts}-{te}] ===')


def show_tables(elements, prefix=""):
    for elem in elements:
        if 'table' in elem:
            ts = elem.get('startIndex', '')
            te = elem.get('endIndex', '')
            print(f'{prefix}=== TABLE [{ts}-{te}] ===')
            for ri, row in enumerate(elem['table'].get('tableRows', [])):
                for ci, cell in enumerate(row.get('tableCells', [])):
                    for p in cell.get('content', []):
                        if 'paragraph' in p:
                            for e in p['paragraph'].get('elements', []):
                                content = e.get('textRun', {}).get('content', '')
                                start = e.get('startIndex', '')
                                end = e.get('endIndex', '')
                                if content.strip():
                                    print(f'{prefix}  R{ri}C{ci} [{start}-{end}] {repr(content.rstrip())}')


def find_text(elements, search):
    for elem in elements:
        if 'paragraph' in elem:
            for e in elem['paragraph'].get('elements', []):
                content = e.get('textRun', {}).get('content', '')
                start = e.get('startIndex', 0)
                idx = 0
                while True:
                    idx = content.find(search, idx)
                    if idx == -1:
                        break
                    abs_start = start + idx
                    abs_end = abs_start + len(search)
                    context = content[max(0, idx-20):idx+len(search)+20].strip()
                    print(f'[{abs_start}-{abs_end}] ...{context}...')
                    idx += len(search)
        if 'table' in elem:
            for row in elem['table'].get('tableRows', []):
                for cell in row.get('tableCells', []):
                    find_text(cell.get('content', []), search)


def main():
    parser = argparse.ArgumentParser(description='Parse Google Docs structure')
    parser.add_argument('file', help='Path to doc JSON file')
    parser.add_argument('--tables', action='store_true', help='Show only table contents')
    parser.add_argument('--find', type=str, help='Find specific text and show indices')
    args = parser.parse_args()

    with open(args.file) as f:
        doc = json.load(f)

    body = doc.get('body', {}).get('content', [])

    if args.find:
        find_text(body, args.find)
    elif args.tables:
        show_tables(body)
    else:
        show_paragraphs(body)


if __name__ == '__main__':
    main()
