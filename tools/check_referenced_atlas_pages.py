#!/usr/bin/env python3
"""Verify every PNG referenced by the *committed* Mega index is present.

Use --staged inside the atlas rebuild action after git add -f to catch
ignored/untracked late atlas pages before pushing a broken index.
"""
import argparse
import json
import subprocess
from pathlib import Path


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--staged", action="store_true",
                        help="Also require every referenced file in git's staged index")
    args = parser.parse_args()

    runtime = Path("assets/runtime")
    index = json.loads((runtime / "mega_atlas_index.json").read_text(encoding="utf-8"))
    expected = set()
    for slug, form in index["forms"].items():
        for kind, variant in form["variants"].items():
            for segment in variant["segments"]:
                expected.add(f"assets/runtime/atlas/battle_{kind}_{segment['sheet']}.png")

    missing = sorted(name for name in expected if not Path(name).is_file())
    unstaged = []
    if args.staged:
        tracked = set(subprocess.check_output(
            ["git", "ls-files", "--cached"], text=True).splitlines())
        unstaged = sorted(expected - tracked)

    print(f"Mega index: {len(index['forms'])} forms, {len(expected)} unique referenced PNG pages")
    if missing:
        print(f"ERROR: {len(missing)} referenced atlas PNG pages missing on disk:")
        for name in missing:
            print("  " + name)
    if unstaged:
        print(f"ERROR: {len(unstaged)} referenced PNG pages absent from Git's index:")
        for name in unstaged:
            print("  " + name)
    if missing or unstaged:
        return 1
    print("PASS: all indexed Mega atlas PNG pages are present"
          + (" and staged/tracked in Git" if args.staged else ""))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
