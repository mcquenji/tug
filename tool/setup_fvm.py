"""Install a verified standalone FVM executable for CI (no bootstrap Dart SDK)."""
import hashlib
import io
import os
from pathlib import Path
import platform
import tarfile
import urllib.request
import zipfile

VERSION = '4.3.1'
CHECKSUMS = {
    'macos-arm64': '9c69d11d792963ce52a2dce457d4ec7f1d9c5da38d17d3088cdfcae4a6e3c525',
    'macos-x64': 'adfee394a827aa9fb9b8a345c8531e2194f638d0b6c15450a3cbbb00c1ccaa8d',
    'linux-arm64': 'ea4c4da1b4dcbf17e250c477711b453d54113fadbebea5b43971d31e00358210',
    'linux-x64': 'ad59c861bdbef80c9f262d30ab28debd374afad0ef4b10b99a47bbab77e08bde',
    'windows-x64': '88867842466eca560ad2481a479d3e5e5de2d7fbaa37eaaa4983030da6f471cb',
}


def main():
    system = {'Darwin': 'macos', 'Linux': 'linux', 'Windows': 'windows'}[platform.system()]
    arch = {'arm64': 'arm64', 'aarch64': 'arm64', 'x86_64': 'x64', 'amd64': 'x64'}[platform.machine().lower()]
    target = f'{system}-{arch}'
    suffix = 'zip' if system == 'windows' else 'tar.gz'
    name = 'fvm.exe' if system == 'windows' else 'fvm'
    url = f'https://github.com/leoafarias/fvm/releases/download/{VERSION}/fvm-{VERSION}-{target}.{suffix}'
    with urllib.request.urlopen(url, timeout=120) as response:
        data = response.read()
    if hashlib.sha256(data).hexdigest() != CHECKSUMS[target]:
        raise RuntimeError('FVM archive checksum mismatch')
    # Extract only the executable, never arbitrary archive paths or symlinks.
    if suffix == 'zip':
        with zipfile.ZipFile(io.BytesIO(data)) as archive:
            matches = [p for p in archive.namelist() if Path(p).name == name]
            if len(matches) != 1:
                raise RuntimeError('Expected exactly one FVM executable')
            binary = archive.read(matches[0])
    else:
        with tarfile.open(fileobj=io.BytesIO(data), mode='r:gz') as archive:
            matches = [m for m in archive.getmembers() if m.isfile() and Path(m.name).name == name]
            if len(matches) != 1:
                raise RuntimeError('Expected exactly one FVM executable')
            binary = archive.extractfile(matches[0]).read()
    directory = Path(os.environ['RUNNER_TEMP']) / 'tug-fvm-bin'
    directory.mkdir(parents=True, exist_ok=True)
    executable = directory / name
    executable.write_bytes(binary)
    executable.chmod(0o755)
    with open(os.environ['GITHUB_PATH'], 'a', encoding='utf-8') as output:
        output.write(f'{directory}\n')
    with open(os.environ['GITHUB_ENV'], 'a', encoding='utf-8') as output:
        output.write(f'FVM_CACHE_PATH={Path.home() / ".cache" / "tug-fvm"}\n')
        output.write(f'PUB_CACHE={Path.home() / ".cache" / "tug-pub"}\n')
    print(f'Installed verified FVM {VERSION} for {target}')


if __name__ == '__main__':
    main()
