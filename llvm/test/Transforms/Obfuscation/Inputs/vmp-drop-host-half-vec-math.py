#!/usr/bin/env python3
"""Remove half-vector minimum/maximum helpers so host x86 lli never
selects llvm.minimum/maximum.v4f16.  FileCheck and AArch64 llc keep
the functions.  Transcendental libm is tried on the host separately."""
import re
import sys

text = open(sys.argv[1], encoding="utf-8").read()
text = re.sub(
    r"(?:^|\n)define[^\n]*@(?:reference|protected)_minmax.*?^}\n",
    "\n",
    text,
    flags=re.M | re.S,
)
sys.stdout.write(text)
