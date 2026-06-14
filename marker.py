#!/usr/bin/env python3
"""Tab-separated path+label generator for fzf.

Reads paths from stdin and outputs: PATH<TAB>LABEL
where LABEL is "[✓] basename" or "[ ] basename".

fzf should use --delimiter='\\t' --with-nth=2 to show labels,
and {1} to get the clean path.

Usage: find /media -type f | python3 marker.py /path/to/watched.txt
"""
import sys
import os

# Derive valid extensions from VIDEO_EXTS env var (set by watch-cli entrypoint)
_raw = os.environ.get("VIDEO_EXTS", "mp4|mkv|avi|mov|flv|webm")
VALID_EXTS = set("." + e for e in _raw.split("|"))


def is_dir_watched(path: str, watched: set[str]) -> bool:
    """Return True if every video file under path is in the watched set."""
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
    watched: set[str] = set()
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
        print(f"{path}\t[{prefix}] {basename}")
