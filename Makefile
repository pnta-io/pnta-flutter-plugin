.PHONY: release
release: ## Cut a release (BUMP=patch|minor|major, default patch)
	@gh workflow run release.yml -f bump=$(or $(BUMP),patch)
