#!/usr/bin/env python3
"""Drop @unsupported_* functions so llc/lli never see scalable / exotic ABI."""
import re
import sys

text = open(sys.argv[1], encoding="utf-8").read()
text = re.sub(
    r"(?:^|\n)define[^\n]*@unsupported_.*?^}\n",
    "\n",
    text,
    flags=re.M | re.S,
)
# Globals that only name dropped @unsupported_* blockaddresses would
# otherwise fail the verifier (dangling BA).  Use ^ / MULTILINE so
# adjacent one-line globals are not skipped after a prior match
# consumes the separating newline.
text = re.sub(
    r"^@[A-Za-z0-9_.]+ *= *[^\n]*blockaddress\(@unsupported_[^\n]+$\n?",
    "",
    text,
    flags=re.M,
)
text = re.sub(
    r"^@[A-Za-z0-9_.]+ *= *[^\n]*\[\n(?:[ \t]+[^\n]*blockaddress\(@unsupported_[^\n]*\n)+\]\n",
    "",
    text,
    flags=re.M,
)
# External pointer / alias wrappers of @jt.unsupported_* tables.
text = re.sub(
    r"^@[A-Za-z0-9_.]+ *= *[^\n]*@jt\.unsupported_[^\n]+$\n?",
    "",
    text,
    flags=re.M,
)
text = re.sub(
    r"\ndeclare[^\n]*@llvm\.aarch64\.neon\.tbl1[^\n]*\n",
    "\n",
    text,
)
sys.stdout.write(text)
