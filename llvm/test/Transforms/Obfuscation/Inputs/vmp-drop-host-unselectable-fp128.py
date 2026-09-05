#!/usr/bin/env python3
"""Drop fp128 minimum/maximum functions host x86 ISel cannot lower."""
import re
import sys

text = open(sys.argv[1], encoding="utf-8").read()
text = re.sub(
    r"(?:^|\n)define[^\n]*@(?:reference|protected)_(?:minimum|maximum)\b.*?^}\n",
    "\n",
    text,
    flags=re.M | re.S,
)
sys.stdout.write(text)
