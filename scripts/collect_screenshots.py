#!/usr/bin/env python3
"""Copy exported xcresult attachments into a clean screenshots folder.

`xcrun xcresulttool export attachments` writes files with opaque names plus a
manifest.json mapping them to the attachment names set in the UI test. This
walks the manifest (tolerant of format differences across Xcode versions) and
copies each PNG to <out>/<attachment-name>.png.
"""
import json
import os
import shutil
import sys


def find_pairs(node, pairs):
    """Recursively find dicts that map an exported file to a readable name."""
    if isinstance(node, dict):
        exported = node.get("exportedFileName") or node.get("fileName")
        name = (
            node.get("suggestedHumanReadableName")
            or node.get("name")
            or node.get("attachmentName")
        )
        if exported and name:
            pairs.append((exported, name))
        for value in node.values():
            find_pairs(value, pairs)
    elif isinstance(node, list):
        for item in node:
            find_pairs(item, pairs)


def main():
    src, dst = sys.argv[1], sys.argv[2]
    os.makedirs(dst, exist_ok=True)

    manifest_path = os.path.join(src, "manifest.json")
    pairs = []
    if os.path.exists(manifest_path):
        with open(manifest_path) as f:
            find_pairs(json.load(f), pairs)

    copied = 0
    for exported, name in pairs:
        source = os.path.join(src, exported)
        # Screenshots only — skip the automatic screen recordings (.mp4).
        if not os.path.exists(source) or not exported.lower().endswith(".png"):
            continue
        base = os.path.splitext(name)[0]
        safe = "".join(c if (c.isalnum() or c in "-_") else "-" for c in base)
        target = os.path.join(dst, safe + ".png")
        shutil.copyfile(source, target)
        copied += 1

    # Fallback: no manifest matches — copy any PNGs with their raw names.
    if copied == 0:
        for entry in os.listdir(src):
            if entry.lower().endswith(".png"):
                shutil.copyfile(os.path.join(src, entry), os.path.join(dst, entry))
                copied += 1

    print(f"copied {copied} screenshots to {dst}")
    if copied == 0:
        sys.exit(1)


if __name__ == "__main__":
    main()
