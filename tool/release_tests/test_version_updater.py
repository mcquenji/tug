import json
from pathlib import Path
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[2]


class VersionUpdaterTests(unittest.TestCase):
    def test_configured_updater_bumps_the_generated_dart_file(self):
        config = json.loads((ROOT / '.versionrc').read_text())
        target = next(item for item in config['bumpFiles'] if item['filename'] == 'lib/gen/version.g.dart')
        source = (ROOT / target['filename']).read_text()
        script = r'''
const fs = require('node:fs');
const {updater, source} = JSON.parse(fs.readFileSync(0, 'utf8'));
const {readVersion, writeVersion} = require(updater);
const results = ['0.3.0', '1.0.0-beta.1+build.2'].map(version => {
  const updated = writeVersion(source, version);
  return {version: readVersion(updated), updated};
});
let rejected = 0;
for (const [contents, version] of [
  ['', '1.0.0'],
  [source + source, '1.0.0'],
  [source, '1.0.0"; malicious'],
]) {
  try { writeVersion(contents, version); } catch { rejected++; }
}
const windows = writeVersion(source.replaceAll('\n', '\r\n'), '0.3.0');
process.stdout.write(JSON.stringify({results, rejected, windows}));
'''
        result = subprocess.run(
            ['node', '-e', script],
            input=json.dumps({'updater': str(ROOT / target['updater']), 'source': source}),
            capture_output=True, text=True, check=True,
        )
        output = json.loads(result.stdout)
        for entry in output['results']:
            self.assertEqual(entry['updated'], '// GENERATED CODE - DO NOT MODIFY BY HAND.\n'
                f'const String pubspecVersion = "{entry["version"]}";\n')
        self.assertEqual(output['rejected'], 3)
        self.assertEqual(output['windows'], output['results'][0]['updated'].replace('\n', '\r\n'))
        self.assertEqual(config['packageFiles'], ['pubspec.yaml'])
