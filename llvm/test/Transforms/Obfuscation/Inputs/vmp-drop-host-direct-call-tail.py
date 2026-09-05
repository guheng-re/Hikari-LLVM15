#!/usr/bin/env python3
"""Drop FileCheck-only direct-call tail functions that host x86
lli/JIT cannot select (bfloat/fp128/constrained/printf).  AArch64
llc still sees the full live module.
"""
import re
import sys

text = open(sys.argv[1], encoding="utf-8").read()
for name in (
    "protected_variadic",
    "protected_variadic_tail",
    "protected_constrained",
    "protected_constrained_tail",
    "protected_bfloat",
    "protected_bfloat_tail",
    "protected_fp128",
    "protected_fp128_tail",
    "protected_trap",
    "bf_id",
    "fp128_id",
):
    text = re.sub(
        r"(?:^|\n)define[^\n]*@" + name + r".*?^}\n",
        "\n",
        text,
        flags=re.M | re.S,
    )
sys.stdout.write(text)
