.PHONY: build serve clean new dev typst deploy

# Build the blog (requires typst-modified binary)
build: typst-modified
	cargo run -- build

# Build the modified Typst binary from submodule
typst-modified:
	@echo "Building modified Typst from submodule..."
	cd typst-src && cargo build --release
	cp typst-src/target/release/typst typst-modified
	@echo "Built typst-modified"

# Serve locally
serve:
	cargo run -- serve --port 9527

# Clean output
clean:
	cargo run -- clean

# Create new post
new:
	@read -p "Post title: " title; \
	cargo run -- new "$$title"

# Build then serve
dev: build serve

# Deploy via rsync (set DEPLOY_TARGET in .env or environment)
deploy: build
	rsync -avzr --delete output/ $(DEPLOY_TARGET)
