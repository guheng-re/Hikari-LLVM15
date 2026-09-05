#!/usr/bin/env python3
"""Drop FileCheck-only helper-family functions that host x86 lli/JIT
cannot select (roundeven/nearbyint/canonicalize/half, extra sat widths).
AArch64 llc still sees the full live module.
"""
import re
import sys

text = open(sys.argv[1], encoding="utf-8").read()
for name in (
    "protected_more_round",
    "protected_canonicalize",
    "protected_int_round",
    "protected_sat",
    "protected_f64",
    "protected_half",
    "protected_fast_ceil",
):
    text = re.sub(
        r"(?:^|\n)define[^\n]*@" + name + r".*?^}\n",
        "\n",
        text,
        flags=re.M | re.S,
    )
sys.stdout.write(text)
