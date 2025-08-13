## langchain-superlinked

Integration package that exposes Superlinked retrieval capabilities via the standard LangChain retriever interface. It lets you plug a Superlinked-powered retriever into LangChain RAG pipelines while keeping your vector storage and schema choices flexible.

### Install

```bash
pip install -U langchain-superlinked superlinked
```

### Quickstart

```python
import superlinked.framework as sl
from langchain_superlinked import SuperlinkedRetriever

class DocumentSchema(sl.Schema):
    id: sl.IdField
    content: sl.String

doc_schema = DocumentSchema()
text_space = sl.TextSimilaritySpace(text=doc_schema.content, model="sentence-transformers/all-MiniLM-L6-v2")
index = sl.Index([text_space])
query = (
    sl.Query(index)
    .find(doc_schema)
    .similar(text_space.text, sl.Param("query_text"))
    .select([doc_schema.content])
)

source = sl.InMemorySource(schema=doc_schema)
executor = sl.InMemoryExecutor(sources=[source], indices=[index])
app = executor.run()
source.put([
    {"id": "1", "content": "Machine learning processes data efficiently."},
    {"id": "2", "content": "NLP understands human language."},
])

retriever = SuperlinkedRetriever(sl_client=app, sl_query=query, page_content_field="content")
docs = retriever.invoke("artificial intelligence", k=2)
```

See more end-to-end examples in `docs/`.

---

## Local development

Prerequisites: Python 3.10–3.13, `uv` installed.

- Setup: `uv sync --all-extras --dev && uv run pre-commit install`
- Lint & type-check: `uv run ruff check . && uv run ruff format --check . && uv run mypy langchain_superlinked`
- Unit tests: `make test`
- Integration tests: `make integration_tests` (skips if `langchain_tests` isn’t installed)
- Smoke test: `make smoke`
- Run examples: `uv run python docs/quickstart_examples.py`

---

## CI/CD overview

On push/PR to `main`, GitHub Actions runs (matrix: 3.10/3.11/3.12):
- Lint: `ruff check .` and `ruff format --check .`
- Type-check: `mypy langchain_superlinked`
- Tests: unit (network disabled) and integration (skips if standard tests unavailable)
- Smoke test: imports the package and symbols
- Build: `python -m build` to produce sdist and wheel (no publish)

Workflow file: `.github/workflows/ci.yml`.

---

## Releasing

- Preferred: tag-based OIDC publish
  - Ensure PyPI Trusted Publisher is configured for this repo.
  - Bump version in `pyproject.toml` using semantic versioning.
  - Tag and push: `git tag vX.Y.Z && git push origin vX.Y.Z`
  - CI will build and publish automatically.
- Manual (fallback):
  - Build artifacts: `make dist`
  - Validate: `uv run twine check dist/*`
  - Publish to PyPI: `uv run twine upload -r pypi dist/*`

After publish, open/refresh the docs PR in the LangChain monorepo to reference the new version if needed. See LangChain’s integration guide for the process: [How to contribute an integration](https://python.langchain.com/docs/contributing/how_to/integrations/#how-to-contribute-an-integration).

---

## Implementation overview

- Primary entrypoint: `langchain_superlinked/retrievers.py` exposes `SuperlinkedRetriever`, a `BaseRetriever`.
- Construction:
  - `sl_client`: Superlinked App (e.g., from `InMemoryExecutor.run()`).
  - `sl_query`: Superlinked `QueryDescriptor` built via `sl.Query(...).find(...).similar(...).select(...)`.
  - `page_content_field`: field from Superlinked results mapped to `Document.page_content`.
  - Optional `metadata_fields`: copied into `Document.metadata` in addition to the always-present `id`.
- Behavior:
  - Accepts runtime parameters (e.g., `k`, weights, filters) and forwards them to the Superlinked query.
  - Handles missing fields gracefully; returns an empty list on upstream exceptions.

---

## Scope and non-goals

This package aims to be the minimal, well-typed LangChain integration layer for Superlinked retrievers. It intentionally does not include:

- Dynamic schema inference or auto-generation for arbitrary datasets. Rationale: datasets vary widely; a robust solution requires additional assumptions (typing, transforms, index strategy), which goes beyond the minimal integration. We recommend implementing this in a separate helper package or cookbook code layered on top (e.g., “schema builders” that emit Superlinked schemas and indices for your domain). The examples in `docs/` illustrate patterns for composing spaces (text, categorical, numeric, recency) that such builders could automate.
- Non-retriever integrations (custom LLMs, embeddings, caches, loaders). These can live in separate packages if needed.

If you have concrete requirements for dynamic schema construction, please open an issue with sample data and desired retrieval behavior so we can discuss an extensible approach that stays decoupled from the core integration.

---

## Links

- Usage examples and scenarios: `docs/`
- LangChain integration guide: [How to contribute an integration](https://python.langchain.com/docs/contributing/how_to/integrations/#how-to-contribute-an-integration)
- Superlinked: `https://superlinked.com`

## License

MIT (see `LICENSE`)
