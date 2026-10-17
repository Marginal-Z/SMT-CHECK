"""Validate desktop startup logs without hiding application or engine failures."""
import argparse
from pathlib import Path
import re
import sys

FAILURE = re.compile(r"Unhandled Exception|(?:ERROR|FATAL):flutter|Failed to start|EXCEPTION CAUGHT BY")
# Flutter corrects this timestamp and continues BeginFrame/draw_frame:
# https://github.com/flutter/flutter/blob/3.47.2/engine/src/flutter/lib/ui/window/platform_configuration.cc
FRAME_CLAMP = re.compile(
    r"^\[ERROR:flutter/lib/ui/window/platform_configuration\.cc\(\d+\)\] "
    r"Reported frame time is older than the last one; clamping\. (\d+) < (\d+) ~= (\d+)$"
)


def validate(text, *, allow_startup_frame_clamp=False):
    failures, clamps = [], 0
    for line in text.splitlines():
        match = FRAME_CLAMP.fullmatch(line.strip())
        if allow_startup_frame_clamp and match:
            current, previous, difference = map(int, match.groups())
            if previous > current and previous - current == difference:
                clamps += 1
                continue
        if FAILURE.search(line):
            failures.append(line)
    return failures, clamps


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("log", type=Path)
    parser.add_argument("--allow-startup-frame-clamp", action="store_true")
    args = parser.parse_args()
    failures, clamps = validate(args.log.read_text(encoding="utf-8", errors="replace"),
                                allow_startup_frame_clamp=args.allow_startup_frame_clamp)
    if clamps:
        print(f"Recorded {clamps} corrected Flutter startup frame timestamps; steady-state checks remain strict.")
    if failures:
        print("\n".join(failures), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
