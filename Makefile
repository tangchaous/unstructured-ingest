PACKAGE_NAME := unstructured_ingest
PIP_VERSION := 23.2.1
ARCH := $(shell uname -m)

###########
# INSTALL #
###########

.PHONY: pip-compile
pip-compile:
	./scripts/pip-compile.sh

.PHONY: install-lint
install-lint:
	pip install -r requirements/lint.txt


.PHONY: install-client
install-client:
	pip install -r requirements/remote/client.txt

.PHONY: install-test
install-test:
	pip install -r requirements/test.txt

.PHONY: install-release
install-release:
	pip install -r requirements/release.txt

.PHONY: install-base
install-base:
	pip install -r requirements/common/base.txt

.PHONY: install-all-connectors
install-all-connectors:
	find requirements/connectors -type f -name "*.txt" -exec pip install -r '{}' ';'

.PHONY: install-all-embedders
install-all-embedders:
	find requirements/embed -type f -name "*.txt" -exec pip install -r '{}' ';'

.PHONY: install-all-deps
install-all-deps:
	find requirements -type f -name "*.txt" ! -name "constraints.txt" -exec pip install -r '{}' ';'

.PHONY: install-docker-compose
install-docker-compose:
	ARCH=${ARCH} ./scripts/install-docker-compose.sh

.PHONY: install-ci
install-ci: install-all-connectors install-all-embedders
	pip install -r requirements/local_partition/pdf.txt
	pip install -r requirements/local_partition/docx.txt
	pip install -r requirements/local_partition/pptx.txt
	pip install -r requirements/local_partition/xlsx.txt
	pip install -r requirements/local_partition/md.txt

###########
#  TIDY   #
###########

.PHONY: tidy
tidy: tidy-black tidy-ruff tidy-autoflake tidy-shell

.PHONY: tidy-shell
tidy-shell:
	shfmt -i 2 -l -w .

.PHONY: tidy-ruff
tidy-ruff:
	ruff check --fix-only --show-fixes .

.PHONY: tidy-black
tidy-black:
	black .

.PHONY: tidy-autoflake
tidy-autoflake:
	autoflake --in-place .

###########
#  CHECK  #
###########

.PHONY: check
check: check-python check-shell

.PHONY: check-python
check-python: check-black check-flake8 check-ruff check-autoflake check-version

.PHONY: check-black
check-black:
	black . --check

.PHONY: check-flake8
check-flake8:
	flake8 .

.PHONY: check-ruff
check-ruff:
	ruff check .

.PHONY: check-autoflake
check-autoflake:
	autoflake --check-diff .

.PHONY: check-shell
check-shell:
	shfmt -i 2 -d .

.PHONY: check-version
check-version:
    # Fail if syncing version would produce changes
	scripts/version-sync.sh -c \
		-f "unstructured_ingest/__version__.py" semver

###########
#  TEST   #
###########
.PHONY: unit-test
unit-test:
	PYTHONPATH=. pytest -sv --cov unstructured_ingest/ test/unit --ignore test/unit/unstructured

.PHONY: unit-test-unstructured
unit-test-unstructured:
	PYTHONPATH=. pytest -sv --cov unstructured_ingest/ test/unit/unstructured

.PHONY: integration-test
integration-test:
	PYTHONPATH=. pytest -sv test/integration

.PHONY: integration-test-partitioners
integration-test-partitioners:
	PYTHONPATH=. pytest -sv test/integration/partitioners --json-report

.PHONY: integration-test-chunkers
integration-test-chunkers:
	PYTHONPATH=. pytest -sv test/integration/chunkers --json-report

.PHONY: integration-test-embedders
integration-test-embedders:
	PYTHONPATH=. pytest -sv test/integration/embedders --json-report

.PHONY: integration-test-connectors-blob-storage
integration-test-connectors-blob-storage:
	PYTHONPATH=. pytest --tags blob_storage -sv test/integration/connectors --json-report

.PHONY: integration-test-connectors-sql
integration-test-connectors-sql:
	PYTHONPATH=. pytest --tags sql -sv test/integration/connectors --json-report

.PHONY: integration-test-connectors-nosql
integration-test-connectors-nosql:
	PYTHONPATH=. pytest --tags nosql -sv test/integration/connectors --json-report

.PHONY: integration-test-connectors-vector-db
integration-test-connectors-vector-db:
	PYTHONPATH=. pytest --tags vector_db -sv test/integration/connectors --json-report

.PHONY: integration-test-connectors-graph-db
integration-test-connectors-graph-db:
	PYTHONPATH=. pytest --tags graph_db -sv test/integration/connectors --json-report

.PHONY: integration-test-connectors-uncategorized
integration-test-connectors-uncategorized:
	PYTHONPATH=. pytest --tags uncategorized -sv test/integration/connectors --json-report

.PHONY: parse-skipped-tests
parse-skipped-tests:
	PYTHONPATH=. python ./scripts/parse_pytest_report.py

.PHONY: check-untagged-tests
check-untagged-tests:
	./scripts/check_untagged_tests.sh

