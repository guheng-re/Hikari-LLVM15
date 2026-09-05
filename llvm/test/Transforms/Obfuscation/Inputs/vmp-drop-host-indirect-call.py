#!/usr/bin/env python3
"""Drop FileCheck-only indirect-call functions that host x86 lli/JIT
cannot select (bfloat).  AArch64 llc still sees the full live module.
"""
import re
import sys

text = open(sys.argv[1], encoding="utf-8").read()
for name in ("protected_bfloat",):
    text = re.sub(
        r"(?:^|\n)define[^\n]*@" + name + r".*?^}\n",
        "\n",
        text,
        flags=re.M | re.S,
    )
sys.stdout.write(text)
