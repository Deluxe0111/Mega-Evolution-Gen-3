#!/usr/bin/env python3
"""Validate maintained Markdown links without depending on network access."""
from pathlib import Path
from urllib.parse import unquote
import re

ROOT = Path(__file__).resolve().parent.parent
SOURCES = [
    "README.md",
    "docs/INSTALLATION.md",
    "docs/DEPENDENCIES.md",
    "docs/ARCHITECTURE.md",
    "docs/MEGA_TRAINER_REVIEW.md",
    "docs/TESTING.md",
    "docs/DEVELOPMENT.md",
    "docs/ROADMAP.md",
    "docs/ALL_MEGA_ROSTER.md",
]
LINK = re.compile(r"\[[^\]]+\]\(([^)]+)\)")
verified = 0
for name in SOURCES:
    path = ROOT / name
    assert path.is_file(), f"Missing maintained document: {name}"
    text = path.read_text(encoding="utf-8")
    for target in LINK.findall(text):
        target = target.strip().split("#", 1)[0].split("?", 1)[0]
        if not target or re.match(r"^(https?://|mailto:|data:)", target, re.I):
            continue
        target = unquote(target.strip("<>"))
        destination = (path.parent / target).resolve()
        assert destination.is_relative_to(ROOT), (
            f"Link escapes project: {name} -> {target}")
        assert destination.exists(), f"Broken Markdown link: {name} -> {target}"
        verified += 1
assert verified >= 15, "Expected a navigable local documentation set"
print(f"PASS: {len(SOURCES)} maintained documents, {verified} local links")
