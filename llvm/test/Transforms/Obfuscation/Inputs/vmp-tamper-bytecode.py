#!/usr/bin/env python3
"""Mutate the first encoded VMP bytecode word without changing IR syntax."""

import pathlib
import re
import sys


def main(argv):
    if len(argv) != 3:
        raise SystemExit("usage: vmp-tamper-bytecode.py <input.ll> <output.ll>")

    source = pathlib.Path(argv[1]).read_text()
    pattern = re.compile(
        r"(@__hikari_vmp_bc = private unnamed_addr constant \[[^\]]+\] \[i64 )(-?\d+)"
    )

    def mutate(match):
        return match.group(1) + str(int(match.group(2)) ^ 1)

    output, count = pattern.subn(mutate, source, count=1)
    if count != 1:
        raise SystemExit("could not find an encoded VMP bytecode word")
    pathlib.Path(argv[2]).write_text(output)


if __name__ == "__main__":
    main(sys.argv)
