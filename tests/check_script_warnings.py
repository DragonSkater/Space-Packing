"""Fails when any script in the project has a GDScript warning.

The engine reports script warnings only to an attached editor, so a headless
import or test run cannot show them. This copies the project's code to a
temporary folder, raises every warning to an error there, and runs the tests,
whose resource test loads every script. Nothing in the real project changes.

Usage:  python tests/check_script_warnings.py <path to the Godot console exe>
"""

import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

COPIED_FOLDERS = ["core", "game", "ui", "debug", "data", "tests"]
COPIED_FILES = ["icon.svg"]
ERROR_LEVEL = 2

# Every warning the engine sets to "warn" by default, and one it leaves off:
# untyped_declaration, which enforces the static typing rule in CLAUDE.md.
WARNINGS = [
    "assert_always_false", "assert_always_true", "confusable_capture_reassignment",
    "confusable_identifier", "confusable_local_declaration", "confusable_local_usage",
    "confusable_temporary_modification", "deprecated_keyword", "empty_file",
    "enum_variable_without_default", "incompatible_ternary", "int_as_enum_without_cast",
    "int_as_enum_without_match", "integer_division", "missing_tool", "narrowing_conversion",
    "redundant_await", "redundant_static_unload", "shadowed_global_identifier",
    "shadowed_variable", "shadowed_variable_base_class", "standalone_expression",
    "standalone_ternary", "static_called_on_instance", "unassigned_variable",
    "unassigned_variable_op_assign", "unreachable_code", "unreachable_pattern",
    "unsafe_void_return", "unused_local_constant", "unused_parameter",
    "unused_private_class_variable", "unused_signal", "unused_variable",
    "untyped_declaration",
]


def strict_settings(settings: str) -> str:
    lines = "".join(f"gdscript/warnings/{name}={ERROR_LEVEL}\n" for name in WARNINGS)
    if "[debug]" in settings:
        return settings.replace("[debug]\n", "[debug]\n\n" + lines, 1)
    return settings + "\n[debug]\n\n" + lines


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__)
        return 2
    godot = sys.argv[1]
    project = Path(__file__).resolve().parent.parent
    with tempfile.TemporaryDirectory() as temporary:
        copy = Path(temporary)
        for folder in COPIED_FOLDERS:
            if (project / folder).is_dir():
                shutil.copytree(project / folder, copy / folder)
        for file_name in COPIED_FILES:
            shutil.copy(project / file_name, copy / file_name)
        settings = (project / "project.godot").read_text(encoding="utf-8")
        (copy / "project.godot").write_text(strict_settings(settings), encoding="utf-8", newline="\n")
        base = [godot, "--headless", "--path", str(copy)]
        subprocess.run(base + ["--import"], capture_output=True)
        run = subprocess.run(base + ["res://tests/test_runner.tscn"], capture_output=True, text=True)
    for line in (run.stdout + run.stderr).splitlines():
        if "Warning treated as error" in line or line.startswith("FAIL") or " tests in " in line:
            print(line.strip())
    if run.returncode == 0:
        print("No script warnings.")
    return run.returncode


if __name__ == "__main__":
    sys.exit(main())
