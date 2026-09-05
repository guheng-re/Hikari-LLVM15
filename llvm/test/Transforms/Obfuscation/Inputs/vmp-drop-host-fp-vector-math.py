#!/usr/bin/env python3
"""Drop FileCheck-only f32/f64 vector functions that host x86 lli/JIT
cannot select.  AArch64 llc still sees the full live module.
"""
import re
import sys

text = open(sys.argv[1], encoding="utf-8").read()
for name in (
    "protected_more",
    "protected_round_rest",
    "protected_transcendental",
    "protected_minmax_ieee",
    "protected_canonicalize",
    "protected_fpclass",
    "protected_sat",
    "protected_f64",
    "protected_fast_sqrt",
):
    text = re.sub(
        r"(?:^|\n)define[^\n]*@" + name + r".*?^}\n",
        "\n",
        text,
        flags=re.M | re.S,
    )
sys.stdout.write(text)
