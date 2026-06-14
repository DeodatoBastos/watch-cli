#!/usr/bin/env python3
import unittest
import tempfile
import os
import subprocess
from pathlib import Path

# Add the parent directory to sys.path to import the modules
import sys
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from toggle_watched import toggle_file, toggle_directory, load_watched, save_watched, VALID_EXTS as TOGGLE_VALID_EXTS
from marker import is_dir_watched, VALID_EXTS as MARKER_VALID_EXTS

class TestWatchedSystem(unittest.TestCase):
    def setUp(self):
        # Create a temporary directory structure for testing
        self.test_dir = tempfile.TemporaryDirectory()
        self.base_path = Path(self.test_dir.name)

        # Setup fake movies and series
        # Movie
        self.movie1 = self.base_path / "Movie 1 (2020).mp4"
        self.movie1.touch()

        # Series: Season 1 (2 eps), Season 2 (2 eps)
        self.series_path = self.base_path / "Cool Series"
        self.s1_path = self.series_path / "Season 1"
        self.s1_path.mkdir(parents=True)
        self.s1e1 = self.s1_path / "S01E01.mkv"
        self.s1e1.touch()
        self.s1e2 = self.s1_path / "S01E02.mkv"
        self.s1e2.touch()

        self.s2_path = self.series_path / "Season 2"
        self.s2_path.mkdir(parents=True)
        self.s2e1 = self.s2_path / "S02E01.mkv"
        self.s2e1.touch()
        self.s2e2 = self.s2_path / "S02E02.mkv"
        self.s2e2.touch()

        # Non-video file
        self.txt_file = self.s1_path / "info.txt"
        self.txt_file.touch()

    def tearDown(self):
        self.test_dir.cleanup()

    def test_toggle_single_file(self):
        watched = set()

        # Toggle on
        watched = toggle_file(watched, str(self.movie1))
        self.assertIn(str(self.movie1), watched)

        # Toggle off
        watched = toggle_file(watched, str(self.movie1))
        self.assertNotIn(str(self.movie1), watched)

    def test_toggle_directory_empty(self):
        empty_dir = self.base_path / "Empty"
        empty_dir.mkdir()

        watched = set()
        watched = toggle_directory(watched, str(empty_dir))
        self.assertEqual(len(watched), 0)

    def test_toggle_directory_all_off_to_all_on(self):
        watched = set()
        watched = toggle_directory(watched, str(self.s1_path))

        self.assertIn(str(self.s1e1), watched)
        self.assertIn(str(self.s1e2), watched)
        self.assertNotIn(str(self.txt_file), watched) # Non-video should not be added

    def test_toggle_directory_partially_on_to_all_on(self):
        watched = {str(self.s1e1)}
        watched = toggle_directory(watched, str(self.s1_path))

        # Should now have both
        self.assertIn(str(self.s1e1), watched)
        self.assertIn(str(self.s1e2), watched)

    def test_toggle_directory_all_on_to_all_off(self):
        watched = {str(self.s1e1), str(self.s1e2)}
        watched = toggle_directory(watched, str(self.s1_path))

        # Should now have neither
        self.assertNotIn(str(self.s1e1), watched)
        self.assertNotIn(str(self.s1e2), watched)

    def test_toggle_recursive_series(self):
        watched = set()
        # Toggle entire series
        watched = toggle_directory(watched, str(self.series_path))

        self.assertIn(str(self.s1e1), watched)
        self.assertIn(str(self.s1e2), watched)
        self.assertIn(str(self.s2e1), watched)
        self.assertIn(str(self.s2e2), watched)

    def test_marker_is_dir_watched(self):
        watched = {str(self.s1e1), str(self.s1e2)}

        # S1 is fully watched
        self.assertTrue(is_dir_watched(str(self.s1_path), watched))

        # S2 is empty of watched
        self.assertFalse(is_dir_watched(str(self.s2_path), watched))

        # Series is partially watched (S1 yes, S2 no)
        self.assertFalse(is_dir_watched(str(self.series_path), watched))

        # Now mark S2 as watched
        watched.update([str(self.s2e1), str(self.s2e2)])

        # Series is fully watched
        self.assertTrue(is_dir_watched(str(self.series_path), watched))

    def test_marker_cli(self):
        # Create a watched file
        watched_file = self.base_path / "watched.txt"
        with open(watched_file, "w") as f:
            f.write(str(self.movie1) + "\n")
            f.write(str(self.s1e1) + "\n")
            f.write(str(self.s1e2) + "\n")

        # Call marker.py via subprocess to test its stdin/stdout behavior
        marker_script = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "marker.py")

        input_data = f"{self.movie1}\n{self.s1_path}\n{self.s2_path}\n{self.series_path}\n"

        result = subprocess.run(
            ["python3", marker_script, str(watched_file)],
            input=input_data,
            text=True,
            capture_output=True,
            check=True
        )

        output = result.stdout.splitlines()
        self.assertEqual(len(output), 4)

        # Movie 1 is watched
        self.assertEqual(output[0], f"{self.movie1}\t[✓] {self.movie1.name}")
        # Season 1 is fully watched
        self.assertEqual(output[1], f"{self.s1_path}\t[✓] {self.s1_path.name}")
        # Season 2 is not watched
        self.assertEqual(output[2], f"{self.s2_path}\t[ ] {self.s2_path.name}")
        # Series is partially watched
        self.assertEqual(output[3], f"{self.series_path}\t[ ] {self.series_path.name}")

if __name__ == "__main__":
    unittest.main()
