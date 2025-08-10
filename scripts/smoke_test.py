from __future__ import annotations


def main() -> int:
    try:
        import langchain_superlinked as pkg  # noqa: F401
    except Exception as exc:  # pragma: no cover - smoke only
        print(f"Import failed: {exc}")
        return 1

    try:
        from langchain_superlinked import SuperlinkedRetriever  # noqa: F401
    except Exception as exc:  # pragma: no cover - smoke only
        print(f"Symbol import failed: {exc}")
        return 2

    print("Smoke OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
