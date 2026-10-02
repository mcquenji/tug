// commit-and-tag-version updater for the generated Dart fallback version.
// Keep the output identical to tool/generate.dart, without needing the SDK.
const declaration = /^const String pubspecVersion = (["'])([^"'\r\n]+)\1;(?=\r?$)/gm;
const semver = /^\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?$/;

function readVersion(contents) {
  const matches = [...contents.matchAll(declaration)];
  if (matches.length !== 1 || !semver.test(matches[0][2])) {
    throw new Error('Expected one pubspecVersion declaration in lib/gen/version.g.dart');
  }
  return matches[0][2];
}

function writeVersion(contents, version) {
  readVersion(contents);
  if (!semver.test(version)) {
    throw new Error('Expected a semantic version for pubspecVersion');
  }
  return contents.replace(declaration, `const String pubspecVersion = ${JSON.stringify(version)};`);
}

module.exports = { readVersion, writeVersion };
