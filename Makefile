.PHONY: all format lint test tests integration_tests help extended_tests setup_dev clean smoke build dist publish

# Default target executed when no arguments are given to make.
all: help

# Define a variable for the test file path.
TEST_FILE ?= tests/unit_tests/
integration_test integration_tests: TEST_FILE = tests/integration_tests/


# unit tests are run with the --disable-socket flag to prevent network calls
test tests:
	uv run pytest --disable-socket --allow-unix-socket $(TEST_FILE)

test_watch:
	uv run ptw --snapshot-update --now . -- -vv $(TEST_FILE)

# integration tests are run without the --disable-socket flag to allow network calls
integration_test integration_tests:
	@set -e; \
	uv run pytest $(TEST_FILE) || code=$$?; \
	if [ "$$code" -ne 5 ] && [ -n "$$code" ]; then exit $$code; fi

setup_dev:
	uv sync --all-extras --dev
	uv run pre-commit install

clean:
	rm -rf .mypy_cache .ruff_cache .pytest_cache dist build *.egg-info

smoke:
	uv run python scripts/smoke_test.py

build:
	uv run python -m build

dist: clean build

publish: dist
	uv run twine check dist/*
	@echo "To publish: uv run twine upload -r pypi dist/*"

######################
# LINTING AND FORMATTING
######################

# Define a variable for Python and notebook files.
PYTHON_FILES=.
MYPY_CACHE=.mypy_cache
lint format: PYTHON_FILES=.
lint_diff format_diff: PYTHON_FILES=$(shell git diff --relative=libs/partners/superlinked --name-only --diff-filter=d master | grep -E '\.py$$|\.ipynb$$')
lint_package: PYTHON_FILES=langchain_superlinked
lint_tests: PYTHON_FILES=tests
lint_tests: MYPY_CACHE=.mypy_cache_test

lint lint_diff lint_package lint_tests:
	[ "$(PYTHON_FILES)" = "" ] || uv run ruff check $(PYTHON_FILES)
	[ "$(PYTHON_FILES)" = "" ] || uv run ruff format $(PYTHON_FILES) --diff
	[ "$(PYTHON_FILES)" = "" ] || mkdir -p $(MYPY_CACHE) && uv run mypy $(PYTHON_FILES) --cache-dir $(MYPY_CACHE)

format format_diff:
	[ "$(PYTHON_FILES)" = "" ] || uv run ruff format $(PYTHON_FILES)
	[ "$(PYTHON_FILES)" = "" ] || uv run ruff check --select I --fix $(PYTHON_FILES)

spell_check:
	uv run codespell --toml pyproject.toml

spell_fix:
	uv run codespell --toml pyproject.toml -w

check_imports: $(shell find langchain_superlinked -name '*.py')
	uv run python ./scripts/check_imports.py $^

######################
# HELP
######################

help:
	@echo '----'
	@echo 'check_imports				- check imports'
	@echo 'format                       - run code formatters'
	@echo 'lint                         - run linters'
	@echo 'test                         - run unit tests'
	@echo 'tests                        - run unit tests'
	@echo 'test TEST_FILE=<test_file>   - run all tests in file'
