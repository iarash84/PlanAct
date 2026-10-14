"""Compatibility entry point; all validation lives in the shared Dart tooling.
See third_party/iranian_holidays/README.md for annual publisher commands.
"""
import shutil
import subprocess
import sys
from pathlib import Path

root = Path(__file__).resolve().parent.parent
dart = shutil.which('dart')
if dart is None:
    raise SystemExit('Dart SDK is required (available with Flutter).')
raise SystemExit(subprocess.call([dart, 'run', str(root / 'tool/generate_iranian_holidays.dart'), *sys.argv[1:]], cwd=root))
