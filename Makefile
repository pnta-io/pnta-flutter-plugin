.PHONY: deps
deps: ## Install dependencies
	@flutter pub get

.PHONY: lint
lint: ## Lint
	@flutter analyze

.PHONY: fmt
fmt: ## Format
	@dart format .

.PHONY: test
test: ## Run tests
	@flutter test

.PHONY: clean
clean:
	@flutter clean

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
