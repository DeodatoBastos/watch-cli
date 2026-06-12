#!/usr/bin/env python3
"""Tab-separated path+label generator for fzf.

Reads paths from stdin and outputs: PATH<TAB>LABEL
where LABEL is "[✓] basename" or "[ ] basename".

fzf should use --delimiter='\\t' --with-nth=2 to show labels,
and {1} to get the clean path.
"""
import sys, os

VALID_EXTS = {".mp4", ".mkv", ".avi", ".mov", ".flv", ".webm"}


def is_dir_watched(path, watched):
    """Check if all video files under a directory are watched."""
    has_videos = False
    for root, _, files in os.walk(path):
        for f in files:
            if os.path.splitext(f)[1].lower() in VALID_EXTS:
                has_videos = True
                if os.path.join(root, f) not in watched:
                    return False
    return has_videos


if __name__ == "__main__":
    watched_file = sys.argv[1]
    watched = set()
    if os.path.exists(watched_file):
        with open(watched_file) as f:
            watched = set(line.strip() for line in f if line.strip())

    for path in sys.stdin.read().splitlines():
        if not path.strip():
            continue

        is_watched = False
        if os.path.isfile(path):
            is_watched = path in watched
        elif os.path.isdir(path):
            is_watched = is_dir_watched(path, watched)

        prefix = "\u2713" if is_watched else " "
        basename = os.path.basename(path)
        # Output: PATH\tLABEL
        print(f"{path}\t[{prefix}] {basename}")
