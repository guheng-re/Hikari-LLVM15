#!/usr/bin/env python3
"""Validate runner metrics and optional llvm-size output for a VMP object."""

import argparse
import json
import os
import re
import subprocess
import sys


def positive_number(value, name):
    if not isinstance(value, (int, float)) or value <= 0:
        raise ValueError("%s must be a positive number" % name)
    return value


def text_size(llvm_size, object_path):
    result = subprocess.run(
        [llvm_size, "--format=sysv", object_path],
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        universal_newlines=True,
    )
    for line in result.stdout.splitlines():
        fields = line.split()
        if len(fields) >= 2 and fields[0] == ".text":
            return int(fields[1], 0)
    raise ValueError("llvm-size did not report a .text section")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--metrics", required=True)
    parser.add_argument("--llvm-size")
    parser.add_argument("--object")
    parser.add_argument("--stats")
    parser.add_argument(
        "--max-text-ratio",
        type=float,
        default=float(os.environ.get("VMP_AARCH64_MAX_TEXT_RATIO", "256")),
    )
    parser.add_argument(
        "--max-runtime-ratio",
        type=float,
        default=float(os.environ.get("VMP_AARCH64_MAX_RUNTIME_RATIO", "512")),
    )
    args = parser.parse_args()

    with open(args.metrics, encoding="utf-8") as metrics_file:
        metrics = json.load(metrics_file)
    reference = metrics["reference"]
    protected = metrics["protected"]
    runtime_ratio = positive_number(
        protected["runtime_ns"], "protected.runtime_ns"
    ) / positive_number(reference["runtime_ns"], "reference.runtime_ns")
    text_ratio = positive_number(
        protected["text_bytes"], "protected.text_bytes"
    ) / positive_number(reference["text_bytes"], "reference.text_bytes")

    object_text = None
    if args.llvm_size or args.object:
        if not args.llvm_size or not args.object:
            parser.error("--llvm-size and --object must be supplied together")
        object_text = text_size(args.llvm_size, args.object)

    if args.stats:
        with open(args.stats, encoding="utf-8") as stats_file:
            if not re.search(r"VMP stats for .*generated-insts=", stats_file.read()):
                raise ValueError("missing VMP statistics report")

    print(
        "VMP metrics: text-ratio=%.3f runtime-ratio=%.3f object-text=%s"
        % (text_ratio, runtime_ratio, object_text if object_text is not None else "n/a")
    )
    if text_ratio > args.max_text_ratio or runtime_ratio > args.max_runtime_ratio:
        raise SystemExit(
            "VMP performance budget exceeded: text %.3f/%.3f, runtime %.3f/%.3f"
            % (text_ratio, args.max_text_ratio, runtime_ratio, args.max_runtime_ratio)
        )


if __name__ == "__main__":
    main()
