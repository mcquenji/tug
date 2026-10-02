import hashlib
import importlib.util
import io
import json
from pathlib import Path
import tarfile
import tempfile
import unittest
from unittest.mock import patch
import zipfile

spec = importlib.util.spec_from_file_location('release', Path(__file__).parents[1] / 'release.py')
release = importlib.util.module_from_spec(spec)
spec.loader.exec_module(release)


class ReleaseTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)

    def archives(self, wrong_target=None):
        for target in release.TARGETS:
            path = self.root / release.filename('0.1.0', target)
            metadata = {'version': '0.1.0', 'commit': 'a' * 40, 'target': wrong_target or target}
            data = json.dumps(metadata).encode()
            if path.suffix == '.zip':
                with zipfile.ZipFile(path, 'w') as archive:
                    archive.writestr('release.json', data)
            else:
                with tarfile.open(path, 'w:gz') as archive:
                    info = tarfile.TarInfo('release.json')
                    info.size = len(data)
                    archive.addfile(info, io.BytesIO(data))

    @patch.object(release, 'validate_tag', return_value={'version': '0.1.0', 'tag': 'v0.1.0', 'commit': 'a' * 40})
    def test_prepare_requires_all_platforms_and_matching_metadata(self, _):
        self.archives(wrong_target='unknown')
        with self.assertRaisesRegex(ValueError, 'metadata mismatch'):
            release.prepare(self.root, 'v0.1.0')
        self.assertFalse((self.root / 'tug.rb').exists())
        self.archives()
        (self.root / release.filename('0.1.0', 'windows-x64')).unlink()
        with self.assertRaises(FileNotFoundError):
            release.prepare(self.root, 'v0.1.0')
        self.assertFalse((self.root / 'tug.rb').exists())

    @patch.object(release, 'validate_tag', return_value={'version': '0.1.0', 'tag': 'v0.1.0', 'commit': 'a' * 40})
    def test_checksums_match_downloads_and_formula_selects_native_assets(self, _):
        self.archives()
        release.prepare(self.root, 'v0.1.0')
        lines = (self.root / 'SHA256SUMS').read_text().splitlines()
        self.assertEqual(len(lines), 5)
        formula = (self.root / 'tug.rb').read_text()
        for target in release.TARGETS:
            path = self.root / release.filename('0.1.0', target)
            digest = hashlib.sha256(path.read_bytes()).hexdigest()
            self.assertIn(f'{digest}  {path.name}', lines)
            if not target.startswith('windows'):
                self.assertIn(path.name, formula)
                self.assertIn(digest, formula)
        self.assertNotIn('windows', formula)
        self.assertIn('shell_output("#{bin}/tug --version")', formula)

    def test_tap_cannot_be_downgraded_by_an_older_tag(self):
        source = self.root / 'new.rb'
        destination = self.root / 'tap' / 'Formula' / 'tug.rb'
        hashes = dict.fromkeys(release.TARGETS, 'a' * 64)
        source.write_text(release.formula('0.2.0', hashes))
        release.update_tap(source, destination)
        current = destination.read_text()
        source.write_text(release.formula('0.1.0', hashes))
        release.update_tap(source, destination)
        self.assertEqual(destination.read_text(), current)

    def test_tag_must_match_pubspec_and_checked_out_commit(self):
        (self.root / 'pubspec.yaml').write_text('name: tug\nversion: 0.1.0\n')
        with patch.object(release, 'ROOT', self.root):
            for tag in ['v0.2.0', 'main', 'v0.1.0-beta', 'v0.1.0\nmalicious']:
                with self.assertRaises(ValueError):
                    release.validate_tag(tag)
            with patch.object(release, 'git', side_effect=['a' * 40, 'b' * 40]):
                with self.assertRaisesRegex(ValueError, 'Checkout'):
                    release.validate_tag('v0.1.0')
            with patch.object(release, 'git', return_value='a' * 40):
                self.assertEqual(release.validate_tag('v0.1.0')['version'], '0.1.0')


if __name__ == '__main__':
    unittest.main()
