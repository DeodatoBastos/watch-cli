#!/usr/bin/env python3
"""Toggle watched status for a file or directory.

Usage: toggle_watched.py WATCHED_FILE TARGET_PATH

For a single file: adds or removes it from the watched list.
For a directory: bulk-toggles all video files inside it.
  - If all videos are watched, unmarks them all.
  - Otherwise, marks them all as watched.
"""
import sys
import os

# Derive valid extensions from VIDEO_EXTS env var (set by watch-cli entrypoint)
_raw = os.environ.get("VIDEO_EXTS", "mp4|mkv|avi|mov|flv|webm")
VALID_EXTS = set("." + e for e in _raw.split("|"))


def load_watched(watched_file: str) -> set[str]:
    """Read watched entries from file, one path per line."""
    if not os.path.exists(watched_file):
        return set()
    with open(watched_file) as f:
        return set(line.strip() for line in f if line.strip())


def save_watched(watched_file: str, watched: set[str]) -> None:
    """Write watched entries back to file, sorted for stability."""
    with open(watched_file, "w") as f:
        for w in sorted(watched):
            f.write(w + "\n")


def collect_videos(directory: str) -> list[str]:
    """Walk a directory tree and return all video file paths."""
    videos = []
    for root, _, files in os.walk(directory):
        for name in files:
            if os.path.splitext(name)[1].lower() in VALID_EXTS:
                videos.append(os.path.join(root, name))
    return videos


def toggle_file(watched: set[str], target: str) -> set[str]:
    """Toggle a single file's watched status."""
    if target in watched:
        watched.discard(target)
    else:
        watched.add(target)
    return watched


def toggle_directory(watched: set[str], target: str) -> set[str]:
    """Toggle all videos in a directory. Unmarks all if fully watched, else marks all."""
    videos = collect_videos(target)
    if not videos:
        return watched

    if all(v in watched for v in videos):
        watched -= set(videos)
    else:
        watched |= set(videos)
    return watched


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print(f"Usage: {sys.argv[0]} WATCHED_FILE TARGET_PATH", file=sys.stderr)
        sys.exit(1)

    watched_file = sys.argv[1]
    target = sys.argv[2]

    # Ensure the file exists
    if not os.path.exists(watched_file):
        open(watched_file, "a").close()

    watched = load_watched(watched_file)

    if os.path.isfile(target):
        watched = toggle_file(watched, target)
    elif os.path.isdir(target):
        watched = toggle_directory(watched, target)
    else:
        print(f"Error: '{target}' is not a valid file or directory", file=sys.stderr)
        sys.exit(1)

    save_watched(watched_file, watched)
