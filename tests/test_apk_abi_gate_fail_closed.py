# SPDX-License-Identifier: GPL-3.0-only
# Scoped RAFCODEPHI CI adapter test, added 2026-11-01.
from pathlib import Path
import subprocess
import tempfile
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / 'ci/validate-apk-abis.sh'


def artifact(folder, stem, abi, libs):
    path = folder / f'termux-api-app_{stem}-{abi}.apk'
    with zipfile.ZipFile(path, 'w') as output:
        output.writestr('AndroidManifest.xml', b'fixture-not-a-real-manifest')
        for lib in libs:
            output.writestr(lib, b'fixture-native-bytes')
    return path


def run(folder, *args):
    return subprocess.run(['bash', str(SCRIPT), str(folder), *args],
                          capture_output=True, text=True, check=False)


class AbiGateTests(unittest.TestCase):
    def test_valid_per_abi_synthetic_zips_are_scoped_only(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d)
            for abi in ('armeabi-v7a', 'arm64-v8a'):
                artifact(p, 'v0.53.0.github.debug', abi,
                         [f'lib/{abi}/libvectra_pulse.so'])
            result = run(p, 'debug', 'armeabi-v7a', 'arm64-v8a')
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(result.stdout.count('APK_ABI_GATE=PASS'), 2)
            self.assertIn('claim_allowed=false', result.stdout)

    def test_duplicate_candidate_fails_closed(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d)
            abi = 'armeabi-v7a'
            for stem in ('v0.53.0', 'v0.53.1'):
                artifact(p, stem, abi, [f'lib/{abi}/libvectra_pulse.so'])
            self.assertEqual(run(p, 'debug', abi).returncode, 65)

    def test_missing_native_library_fails(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d)
            artifact(p, 'v1', 'armeabi-v7a', ['assets/a.dat'])
            self.assertEqual(run(p, 'debug', 'armeabi-v7a').returncode, 68)

    def test_foreign_abi_fails(self):
        with tempfile.TemporaryDirectory() as d:
            p  = Path(d)
            artifact(p, 'v1', 'armeabi-v7a',
                       ['lib/armeabi-v7a/libvectra_pulse.so', 'lib/arm64-v8a/libevil.so'])
            self.assertEqual(run(p, 'debug', 'armeabi-v7a').returncode, 69)

    def test_corrupt_apk_fails(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d)
            (p / 'termux-api-app_v1-armeabi-v7a.apk').write_bytes(b'not zip')
            self.assertEqual(run(p, 'debug', 'armeabi-v7a').returncode, 67)

    def test_duplicate_or_unknown_abi_fails(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d)
            self.assertEqual(run(p, 'debug', 'armeabi-v7a', 'armeabi-v7a').returncode, 64)
            self.assertEqual(run(p, 'debug', 'mips').returncode, 64)
            self.assertEqual(run(p, 'not-a-variant', 'armeabi-v7a').returncode, 64)


if __name__ == '__main__':
    unittest.main()
