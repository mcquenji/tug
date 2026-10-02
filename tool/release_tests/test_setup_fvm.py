import importlib.util
import io
from pathlib import Path
import tarfile
import tempfile
import unittest

spec = importlib.util.spec_from_file_location('setup_fvm', Path(__file__).parents[1] / 'setup_fvm.py')
setup_fvm = importlib.util.module_from_spec(spec)
spec.loader.exec_module(setup_fvm)


def bundle(names):
    output = io.BytesIO()
    with tarfile.open(fileobj=output, mode='w:gz') as archive:
        for name in names:
            info = tarfile.TarInfo(name)
            info.size = 4
            info.mode = 0o755
            archive.addfile(info, io.BytesIO(b'data'))
    return output.getvalue()


class FvmSetupTests(unittest.TestCase):
    def test_preserves_launcher_runtime_and_snapshot(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            setup_fvm.extract_bundle(bundle(['fvm/fvm', 'fvm/src/dart', 'fvm/src/fvm.dart.snapshot']), 'tar.gz', root)
            self.assertEqual((root / 'fvm/src/dart').read_bytes(), b'data')
            self.assertTrue((root / 'fvm/src/fvm.dart.snapshot').exists())

    def test_rejects_paths_outside_destination(self):
        for name in ['../escape', '/absolute', 'C:/windows', r'..\escape']:
            with self.subTest(name=name), tempfile.TemporaryDirectory() as directory:
                with self.assertRaises(ValueError):
                    setup_fvm.extract_bundle(bundle([name]), 'tar.gz', Path(directory))
