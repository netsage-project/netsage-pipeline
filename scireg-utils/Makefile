# Variables
BINARY_NAME=scireg2mmdb
BUILD_DIR=build
GOFILES=$(wildcard *.go)

# Default target
all: build

init:
	@echo "Initializing Go module..."
	@go mod init generate_mmdb
	@echo "Fetching dependencies..."
	@go get github.com/maxmind/mmdbwriter

# Build the binary for the current platform
build: $(GOFILES)
	@echo "Building $(BINARY_NAME)..."
	@go build -o $(BUILD_DIR)/$(BINARY_NAME) scireg2mmdb.go
	@echo "Build complete!"

# Clean up build artifacts
clean:
	@echo "Cleaning up..."
	@rm -rf $(BUILD_DIR)/*
	@echo "Clean complete!"

# Run tests
test:
	@echo "Running tests..."
	@go test ./...
	@echo "Tests complete!"

# Cross-compile for multiple platforms
platforms:
	@$(MAKE) build-windows build-darwin build-linux

build-windows:
	@echo "Building for Windows..."
	@GOOS=windows GOARCH=amd64 go build -o $(BUILD_DIR)/$(BINARY_NAME)-windows-amd64.exe

build-darwin:
	@echo "Building for macOS..."
	@GOOS=darwin GOARCH=amd64 go build -o $(BUILD_DIR)/$(BINARY_NAME)-darwin-amd64

build-linux:
	@echo "Building for Linux..."
	@GOOS=linux GOARCH=amd64 go build -o $(BUILD_DIR)/$(BINARY_NAME)-linux-amd64

# Install the binary to $GOPATH/bin
install:
	@echo "Installing $(BINARY_NAME) to $(GOPATH)/bin..."
	@go install

# Phony targets
.PHONY: all build clean test platforms build-windows build-darwin build-linux install


