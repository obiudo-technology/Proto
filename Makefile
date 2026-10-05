# Developer tasks for the SettlementOne contract.
#
# Only Docker is required: every buf/Go command runs inside the toolchain
# image built from ./Dockerfile (buf + Go + pinned generators). The image is
# rebuilt automatically when Dockerfile, go.mod or go.sum change (Docker's
# layer cache makes this near-instant otherwise).
#
#   make generate   regenerate gen/go from the .proto files (commit the result)
#   make check      everything CI checks
#   make shell      a shell inside the toolchain container

TOOLS_IMAGE := settlementone-proto-tools:local

# Runs as your host user (generated files stay yours, not root's), with the
# repo mounted, and with no network: everything was pre-fetched into the image.
DOCKER_FLAGS := --rm \
	--user $(shell id -u):$(shell id -g) \
	--network none \
	--volume "$(CURDIR)":/workspace \
	--workdir /workspace
RUN := docker run $(DOCKER_FLAGS) $(TOOLS_IMAGE)

.PHONY: tools generate lint format format-check breaking build verify-clean check shell

# Build (or reuse from cache) the toolchain image.
tools:
	@docker build --quiet --tag $(TOOLS_IMAGE) . >/dev/null

# Regenerate gen/go from the .proto files.
generate: tools
	$(RUN) buf generate

lint: tools
	$(RUN) buf lint

# Rewrite .proto files into buf's canonical format.
format: tools
	$(RUN) buf format -w

# Fail if any .proto file is not in canonical format.
format-check: tools
	$(RUN) buf format -d --exit-code

# Compare against local main; anything reported would break existing clients.
breaking: tools
	$(RUN) buf breaking --against '.git#branch=main'

# Compile and vet the generated Go code.
build: tools
	$(RUN) sh -c 'go build ./... && go vet ./...'

# Fail if regenerating changed gen/ or the module files compared with what is
# staged/committed, i.e. the .proto and its generated code disagree. Staged
# changes are fine; unstaged edits or new untracked files under gen/ are not.
verify-clean:
	@git diff --quiet -- gen go.mod go.sum && \
		test -z "$$(git ls-files --others --exclude-standard -- gen)" || \
		(git status --short -- gen go.mod go.sum; echo "gen/ or go.mod/go.sum is stale: run 'make generate' and commit the result"; exit 1)

check: lint format-check breaking generate build verify-clean

shell: tools
	docker run -it $(DOCKER_FLAGS) $(TOOLS_IMAGE) sh
