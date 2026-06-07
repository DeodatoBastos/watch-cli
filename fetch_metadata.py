#!/usr/bin/env python3
import os
import sys
import re
import json
import urllib.request
import urllib.parse
from pathlib import Path

CACHE_DIR = Path.home() / ".cache" / "watch_cli"
POSTER_DIR = CACHE_DIR / "posters"
METADATA_DIR = CACHE_DIR / "metadata"

POSTER_DIR.mkdir(parents=True, exist_ok=True)
METADATA_DIR.mkdir(parents=True, exist_ok=True)

# ANSI escape codes for beautiful styling
BOLD = "\033[1m"
GREEN = "\033[32m"
YELLOW = "\033[33m"
CYAN = "\033[36m"
RESET = "\033[0m"

def clean_title(title):
    # Remove file extensions
    title = re.sub(r'\.(mp4|mkv|avi|mov|flv|webm)$', '', title, flags=re.IGNORECASE)
    # Remove year ranges like (2019-2026) or years like (2024)
    year_match = re.search(r'\((\d{4})(?:-\d{4})?\)', title)
    year = year_match.group(1) if year_match else None
    title_clean = re.sub(r'\(\d{4}(?:-\d{4})?\)', '', title)
    # Remove other brackets or trailing details
    title_clean = re.sub(r'\[.*?\]', '', title_clean)
    title_clean = re.sub(r'Season \d+.*', '', title_clean, flags=re.IGNORECASE)
    title_clean = re.sub(r'\bS\d+E\d+\b.*', '', title_clean, flags=re.IGNORECASE)
    title_clean = title_clean.strip()
    return title_clean, year

def get_url_json(url):
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'watch-cli/1.0 (contact: deodatobasto@gmail.com)'})
        with urllib.request.urlopen(req, timeout=5) as response:
            return json.loads(response.read().decode('utf-8'))
    except Exception as e:
        return None

def download_image(url, dest_path):
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'watch-cli/1.0'})
        with urllib.request.urlopen(req, timeout=10) as response:
            with open(dest_path, 'wb') as f:
                f.write(response.read())
        return True
    except Exception as e:
        return False

def fetch_tvmaze(query):
    url = f"https://api.tvmaze.com/singlesearch/shows?q={urllib.parse.quote(query)}"
    data = get_url_json(url)
    if not data:
        return None

    summary = data.get('summary', '')
    if summary:
        summary = re.sub(r'<[^>]*>', '', summary) # strip HTML

    year = data.get('premiered', '')
    if year:
        year = year.split('-')[0]

    return {
        'title': data.get('name', query),
        'type': 'Series',
        'year': year,
        'genres': ', '.join(data.get('genres', [])),
        'rating': str(data.get('rating', {}).get('average') or 'N/A'),
        'summary': summary,
        'poster_url': data.get('image', {}).get('original') or data.get('image', {}).get('medium') or ''
    }

def find_poster_image(images, query):
    query_words = [w.lower() for w in re.findall(r'\w+', query) if len(w) > 2]
    candidates = []
    for img in images:
        title = img.get('title', '')
        if not title.startswith('File:'):
            continue
        if any(x in title.lower() for x in ['logo.svg', 'symbol', 'icon', 'category', 'class', 'wikidata']):
            continue
        if not any(title.lower().endswith(ext) for ext in ['.jpg', '.jpeg', '.png']):
            continue
        candidates.append(title)

    if not candidates:
        return None

    # Priority 1: Contains "poster", "cover", "banner"
    for title in candidates:
        if any(x in title.lower() for x in ['poster', 'cover', 'banner']):
            return title

    # Priority 2: Contains query words
    for title in candidates:
        if any(w in title.lower() for w in query_words):
            return title

    # Priority 3: First candidate
    return candidates[0]

def fetch_wikipedia(query, media_type, year_context=None):
    # Formulate search term
    if media_type == 'movie' and 'film' not in query.lower() and 'movie' not in query.lower():
        search_term = f"{query} {year_context} film" if year_context else f"{query} film"
    else:
        search_term = query

    search_url = f"https://en.wikipedia.org/w/api.php?action=query&list=search&srsearch={urllib.parse.quote(search_term)}&format=json"
    search_data = get_url_json(search_url)
    if not search_data or not search_data.get('query', {}).get('search'):
        search_url = f"https://en.wikipedia.org/w/api.php?action=query&list=search&srsearch={urllib.parse.quote(query)}&format=json"
        search_data = get_url_json(search_url)
        if not search_data or not search_data.get('query', {}).get('search'):
            return None

    page_title = search_data['query']['search'][0]['title']

    # Page details (text synopsis and pageimages check)
    details_url = f"https://en.wikipedia.org/w/api.php?action=query&format=json&prop=pageimages|extracts&exintro&explaintext&exsentences=3&piprop=original&titles={urllib.parse.quote(page_title)}"
    details_data = get_url_json(details_url)
    if not details_data or not details_data.get('query', {}).get('pages'):
        return None

    pages = details_data['query']['pages']
    page_id = list(pages.keys())[0]
    page = pages[page_id]

    summary = page.get('extract', '')
    year_match = re.search(r'\b(19\d\d|20\d\d)\b', summary)
    year = year_match.group(1) if year_match else (year_context or 'N/A')

    # Try getting the poster from pageimages
    poster_url = page.get('original', {}).get('source', '')

    # If not found via pageimages, query all article images and resolve the poster file
    if not poster_url:
        images_url = f"https://en.wikipedia.org/w/api.php?action=query&titles={urllib.parse.quote(page_title)}&prop=images&format=json"
        images_data = get_url_json(images_url)
        if images_data and images_data.get('query', {}).get('pages'):
            img_pages = images_data['query']['pages']
            img_page_id = list(img_pages.keys())[0]
            images = img_pages[img_page_id].get('images', [])

            best_img = find_poster_image(images, query)
            if best_img:
                info_url = f"https://en.wikipedia.org/w/api.php?action=query&titles={urllib.parse.quote(best_img)}&prop=imageinfo&iiprop=url&format=json"
                info_data = get_url_json(info_url)
                if info_data and info_data.get('query', {}).get('pages'):
                    info_pages = info_data['query']['pages']
                    info_page_id = list(info_pages.keys())[0]
                    img_info = info_pages[info_page_id].get('imageinfo', [{}])[0]
                    poster_url = img_info.get('url', '')

    return {
        'title': page_title,
        'type': 'Movie' if media_type == 'movie' else 'Series',
        'year': year,
        'genres': 'N/A',
        'rating': 'N/A',
        'summary': summary,
        'poster_url': poster_url
    }

def fetch_omdb(query, media_type, api_key):
    url = f"http://www.omdbapi.com/?apikey={api_key}&t={urllib.parse.quote(query)}"
    data = get_url_json(url)
    if not data or data.get('Response') == 'False':
        return None

    return {
        'title': data.get('Title', query),
        'type': 'Movie' if data.get('Type') == 'movie' else 'Series',
        'year': data.get('Year', 'N/A').split('–')[0],
        'genres': data.get('Genre', 'N/A'),
        'rating': data.get('imdbRating', 'N/A'),
        'summary': data.get('Plot', 'No synopsis available.'),
        'poster_url': data.get('Poster', '') if data.get('Poster') != 'N/A' else ''
    }

def main():
    if len(sys.argv) < 3:
        print("Usage: fetch_metadata.py <movie|series> <item_name>")
        sys.exit(1)

    media_type = sys.argv[1].lower()
    raw_name = sys.argv[2]

    title, year_context = clean_title(raw_name)

    safe_name = re.sub(r'[^a-zA-Z0-9_-]', '_', title).lower()
    metadata_file = METADATA_DIR / f"{safe_name}.json"
    poster_file = POSTER_DIR / f"{safe_name}.jpg"

    metadata = None
    if metadata_file.exists():
        try:
            with open(metadata_file, 'r') as f:
                metadata = json.load(f)
        except:
            pass

    if not metadata:
        api_key = os.environ.get("OMDB_API_KEY")
        if api_key:
            metadata = fetch_omdb(title, media_type, api_key)

        if not metadata:
            if media_type == 'series':
                metadata = fetch_tvmaze(title)
                if not metadata:
                    metadata = fetch_wikipedia(title, 'series', year_context)
            else:
                metadata = fetch_wikipedia(title, 'movie', year_context)

        if not metadata:
            metadata = {
                'title': title,
                'type': 'Movie' if media_type == 'movie' else 'Series',
                'year': year_context or 'N/A',
                'genres': 'N/A',
                'rating': 'N/A',
                'summary': 'No synopsis available.',
                'poster_url': ''
            }

        if year_context and (metadata['year'] == 'N/A' or not metadata['year']):
            metadata['year'] = year_context

        if metadata.get('poster_url'):
            download_image(metadata['poster_url'], poster_file)
            metadata['poster_path'] = str(poster_file)
        else:
            metadata['poster_path'] = ''

        with open(metadata_file, 'w') as f:
            json.dump(metadata, f)
    else:
        # If metadata is cached but the poster image does not exist locally (or is empty), try to download it
        poster_exists = os.path.exists(poster_file) and os.path.getsize(poster_file) > 0
        if not poster_exists and metadata.get('poster_url'):
            if download_image(metadata['poster_url'], poster_file):
                metadata['poster_path'] = str(poster_file)
                try:
                    with open(metadata_file, 'w') as f:
                        json.dump(metadata, f)
                except:
                    pass

    print(f"{BOLD}{CYAN}{metadata['title']}{RESET} ({metadata['year']})")
    print(f"{BOLD}Type:{RESET} {metadata['type']}")
    if metadata.get('genres') and metadata['genres'] != 'N/A':
        print(f"{BOLD}Genres:{RESET} {metadata['genres']}")
    if metadata.get('rating') and metadata['rating'] != 'N/A':
        print(f"{BOLD}Rating:{RESET} ⭐ {metadata['rating']}/10")
    print(f"{BOLD}Synopsis:{RESET}")
    print(metadata['summary'])

    if os.path.exists(poster_file) and os.path.getsize(poster_file) > 0:
        print(f"__POSTER_PATH__:{poster_file}")
    else:
        print("__POSTER_PATH__:")

if __name__ == '__main__':
    main()
