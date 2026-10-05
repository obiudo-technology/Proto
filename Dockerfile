# syntax=docker/dockerfile:1
#
# Toolchain image for this repo: buf + Go + the pinned code generators, so a
# fresh clone needs nothing but Docker. The Makefile builds it and runs every
# command inside it with the repo mounted at /workspace.
#
# Versions: BUF_VERSION must match `version:` in .github/workflows/ci.yml;
# GO_VERSION must match the `go` line in go.mod. The generators themselves are
# pinned in go.mod (tool directives) and pre-built below.

ARG BUF_VERSION=1.73.0
ARG GO_VERSION=1.26

# The official buf image, used only as a source for its binary.
FROM bufbuild/buf:${BUF_VERSION} AS buf

FROM golang:${GO_VERSION}-alpine

# git: buf reads `.git#branch=main` for breaking-change checks.
RUN apk add --no-cache git

COPY --from=buf /usr/local/bin/buf /usr/local/bin/buf

# Use exactly the Go in this image; never auto-download another toolchain.
# GOCACHE lives in the image so the pre-built generators below are reused.
ENV GOTOOLCHAIN=local \
    GOCACHE=/cache/go-build \
    HOME=/tmp

# The Makefile runs as your host user, so the repo is "owned" by another uid
# inside the container; tell git that's expected.
RUN git config --system --add safe.directory /workspace

# Download every module in go.mod (incl. the gRPC/protobuf runtime used by
# `go build`) and pre-build the generators, so runs can be fully offline.
# Re-runs only when go.mod/go.sum change.
WORKDIR /deps
COPY go.mod go.sum ./
RUN go mod download \
    && go tool protoc-gen-go --version \
    && go tool protoc-gen-go-grpc --version \
    && chmod -R a+rwX /go /cache

WORKDIR /workspace
