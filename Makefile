.PHONY: release
release: ## Cut a release (BUMP=patch|minor|major, default patch)
	@gh workflow run release.yml -f bump=$(or $(BUMP),patch)

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
