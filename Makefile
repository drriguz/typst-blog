.PHONY: build serve clean new dev typst deploy fonts

# Build the blog
build: typst-modified fonts
	cargo run -- build

# Build the modified Typst binary from submodule
typst-modified:
	@echo "Building modified Typst from submodule..."
	cd typst-src && cargo build --release
	cp typst-src/target/release/typst typst-modified
	@echo "Built typst-modified"

# Install fonts for local development (requires apt-get on Linux)
fonts:
	sudo apt-get update
	sudo apt-get install -y \
		fonts-libertinus \
		fonts-new-computer-modern \
		fonts-cascadia-code \
		fonts-noto-cjk

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
