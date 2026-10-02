"""Install a verified standalone FVM executable for CI (no bootstrap Dart SDK)."""
import hashlib
import io
import os
from pathlib import Path, PurePosixPath
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


def extract_bundle(data, suffix, directory):
    # Some platforms ship a launcher plus src/dart and a snapshot. Preserve the
    # whole verified bundle, while refusing links and paths outside the target.
    def destination(name):
        relative = PurePosixPath(name)
        if relative.is_absolute() or '..' in relative.parts or '\\' in name or ':' in name:
            raise ValueError('Unsafe path in FVM archive')
        return directory.joinpath(*relative.parts)

    if suffix == 'zip':
        with zipfile.ZipFile(io.BytesIO(data)) as archive:
            for member in archive.infolist():
                path = destination(member.filename)
                if member.is_dir():
                    path.mkdir(parents=True, exist_ok=True)
                else:
                    path.parent.mkdir(parents=True, exist_ok=True)
                    path.write_bytes(archive.read(member))
    else:
        with tarfile.open(fileobj=io.BytesIO(data), mode='r:gz') as archive:
            for member in archive.getmembers():
                path = destination(member.name)
                if member.isdir():
                    path.mkdir(parents=True, exist_ok=True)
                elif member.isfile():
                    path.parent.mkdir(parents=True, exist_ok=True)
                    path.write_bytes(archive.extractfile(member).read())
                    path.chmod(member.mode & 0o777)
                else:
                    raise ValueError('Unsupported link or special file in FVM archive')


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
    directory = Path(os.environ['RUNNER_TEMP']) / 'tug-fvm-bin'
    extract_bundle(data, suffix, directory)
    matches = [p for p in directory.rglob(name) if p.is_file()]
    if len(matches) != 1:
        raise RuntimeError('Expected exactly one FVM launcher')
    directory = matches[0].parent
    with open(os.environ['GITHUB_PATH'], 'a', encoding='utf-8') as output:
        output.write(f'{directory}\n')
    with open(os.environ['GITHUB_ENV'], 'a', encoding='utf-8') as output:
        output.write(f'FVM_CACHE_PATH={Path.home() / ".cache" / "tug-fvm"}\n')
        output.write(f'PUB_CACHE={Path.home() / ".cache" / "tug-pub"}\n')
    print(f'Installed verified FVM {VERSION} for {target}')


if __name__ == '__main__':
    main()
