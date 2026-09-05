#!/usr/bin/env python3
"""Remove @protected_minmax so host x86 lli never sees llvm.minimum.f16."""
import re
import sys

text = open(sys.argv[1], encoding="utf-8").read()
text = re.sub(
    r"(?:^|\n)define[^\n]*@protected_minmax.*?^}\n",
    "\n",
    text,
    flags=re.M | re.S,
)
sys.stdout.write(text)
