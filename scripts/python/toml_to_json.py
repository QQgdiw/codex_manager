#!/usr/bin/env python3
"""Convert one TOML document to JSON using Python's standard library."""

from __future__ import annotations

import json
import sys
import tomllib
from datetime import date, datetime, time
from pathlib import Path
from typing import NoReturn


def fail(message: str, exit_code: int) -> NoReturn:
    print(message, file=sys.stderr)
    raise SystemExit(exit_code)


def json_default(value: object) -> str:
    if isinstance(value, (date, datetime, time)):
        return value.isoformat()
    raise TypeError(f"Object of type {type(value).__name__} is not JSON serializable")


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        fail("usage: toml_to_json.py <input.toml>", 2)

    input_path = Path(argv[1])
    try:
        with input_path.open("rb") as stream:
            document = tomllib.load(stream)
    except (FileNotFoundError, IsADirectoryError, PermissionError) as exc:
        fail(f"input error: {exc}", 2)
    except tomllib.TOMLDecodeError as exc:
        fail(f"TOML syntax error: {exc}", 2)
    except OSError as exc:
        fail(f"input error: {exc}", 2)

    try:
        json.dump(
            document,
            sys.stdout,
            ensure_ascii=False,
            separators=(",", ":"),
            default=json_default,
        )
        sys.stdout.write("\n")
    except Exception as exc:
        fail(f"runtime error: {exc}", 3)

    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main(sys.argv))
    except SystemExit:
        raise
    except Exception as exc:
        fail(f"runtime error: {exc}", 3)
