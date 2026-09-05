#!/usr/bin/env python3
"""Remove half vector.reduce.fmin/fmax helpers so host x86 lli never
selects llvm.vector.reduce.fmin/fmax.f16.  FileCheck and AArch64 llc
keep the functions."""
import re
import sys

text = open(sys.argv[1], encoding="utf-8").read()
text = re.sub(
    r"(?:^|\n)define[^\n]*@(?:reference|protected)_reduce_minmax.*?^}\n",
    "\n",
    text,
    flags=re.M | re.S,
)
sys.stdout.write(text)
