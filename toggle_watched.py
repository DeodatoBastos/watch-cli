#!/usr/bin/env python3
import sys, os

if __name__ == "__main__":
    watched_file = sys.argv[1]
    target = sys.argv[2]
    valid_exts = {".mp4", ".mkv", ".avi", ".mov", ".flv", ".webm"}

    watched = set()
    if os.path.exists(watched_file):
        with open(watched_file) as f:
            watched = set(line.strip() for line in f if line.strip())

    videos = []
    for root, _, files in os.walk(target):
        for f in files:
            if os.path.splitext(f)[1].lower() in valid_exts:
                videos.append(os.path.join(root, f))

    if not videos:
        sys.exit(0)

    all_watched = all(v in watched for v in videos)

    if all_watched:
        watched -= set(videos)
    else:
        watched |= set(videos)

    with open(watched_file, "w") as f:
        for w in sorted(watched):
            f.write(w + "\n")
