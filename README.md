# Watch CLI

Watch CLI is a beautiful, extremely fast, terminal-based user interface (TUI) for browsing and watching your local video library. It automatically organizes your movies and TV shows, fetches rich metadata and posters from the internet, and lets you play your media seamlessly—all without ever leaving your terminal.

## Features

- **Blazing Fast TUI:** Powered by `fzf`, the interface is incredibly responsive, allowing you to instantly search through hundreds of video files.
- **Dynamic Organization:** Automatically detects the difference between standalone Movies and TV Series (with seasons and episodes).
- **Rich Metadata:** Fetches and caches synopses, genres, release years, and ratings directly from OMDB, TMDB, and Wikipedia.
- **Local File Inspection:** Extracts video resolution, codec, and duration using `ffprobe`. Automatically calculates the average episode duration for TV series.
- **Native High-Res Image Rendering:** Features a custom integration with the Kitty terminal graphics protocol to display full-resolution, correctly scaled movie posters alongside the metadata text.
- **Character Art Fallback:** For terminals that don't support Kitty graphics, it seamlessly falls back to rendering colored ANSI character art posters using `chafa`.
- **Smart Playback:** Launches videos directly in Kitty (if supported) or falls back to your preferred full-screen GUI video player.

## Installation & Requirements

Ensure you have the following dependencies installed on your system:

- `bash` (Unix shell)
- `fzf` (A command-line fuzzy finder)
- `ffmpeg` / `ffprobe` (For local video metadata extraction)
- `python3` (For the metadata fetching client)
- **Optional but recommended:**
  - [Kitty Terminal](https://sw.kovidgoyal.net/kitty/) (For rendering beautiful high-res posters directly in the terminal)
  - `chafa` (For character art posters on non-Kitty terminals)

Simply clone this repository and ensure the `watch-cli` script is executable:

```bash
chmod +x watch-cli
```

You can then link it to your `$PATH` for global access:
```bash
ln -s /path/to/watch-cli/watch-cli /usr/local/bin/watch-cli
```

## How to Use

1. Run the `watch-cli` script from your terminal:
   ```bash
   ./watch-cli
   ```
2. **Setup Library Path:** On first run, it will ask you for the directory where your media is stored. Simply type the absolute path (e.g., `/home/user/Movies`).
3. **Browse:** Use your arrow keys (or type to fuzzy-search) through your collection. The right pane will display detailed information about the selected movie or series, complete with a poster.
4. **Select:** Press `Enter` to select a movie or delve into a series to pick a specific season and episode.
5. **Play:** Once a file is selected, press `Enter` to launch the video player.

## API Keys (Optional)

To get the most accurate and complete metadata, it is highly recommended to provide API keys for the metadata providers. You can export these as environment variables before running the script:

```bash
export OMDB_API_KEY="your_omdb_key"
export TMDB_API_KEY="your_tmdb_key"
```

## Credits & Attributions

This project relies on the following incredible APIs to fetch metadata and posters. We extend our sincere thanks to them!

<div style="display: flex; align-items: center; gap: 20px;">
  <a href="https://www.themoviedb.org/">
    <img src="https://www.themoviedb.org/assets/2/v4/logos/v2/blue_short-8e7b30f73a4020692ccca9c88bafe5dcb6f8a62a4c6bc55cd9ba82bb2cd95f6c.svg" alt="TMDB Logo" width="150" />
  </a>
  <p>
    This product uses the TMDB API but is not endorsed or certified by TMDB.
  </p>
</div>

<br/>

<div style="display: flex; align-items: center; gap: 20px;">
  <a href="https://www.omdbapi.com/">
    <h3>OMDb API</h3>
  </a>
  <p>
    Metadata and posters are also provided by the OMDb API.
  </p>
</div>
