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

# Download fonts for local development
fonts:
	@mkdir -p static/fonts
	@if [ ! -f static/fonts/SourceHanSansSC-Regular.otf ]; then \
		echo "Downloading Source Han Sans SC..."; \
		curl -sL "https://github.com/adobe-fonts/source-han-sans/releases/download/2.005R/09_SourceHanSansSC.zip" -o /tmp/shs.zip; \
		unzip -j /tmp/shs.zip "*.otf" -d static/fonts/; \
		rm /tmp/shs.zip; \
	fi
	@if [ ! -f static/fonts/FiraMath-Regular.otf ]; then \
		echo "Downloading FiraMath..."; \
		curl -sL "https://github.com/firamath/firamath/releases/download/v0.3.4/FiraMath-Regular.otf" -o static/fonts/FiraMath-Regular.otf; \
	fi
	@if [ ! -f static/fonts/CascadiaCode-Regular.ttf ]; then \
		echo "Downloading Cascadia Code..."; \
		curl -sL "https://github.com/microsoft/cascadia-code/releases/download/v2407.24/CascadiaCode-2407.24.zip" -o /tmp/cascadia.zip; \
		unzip -j /tmp/cascadia.zip "ttf/static/CascadiaCode-Regular.ttf" -d static/fonts/; \
		rm /tmp/cascadia.zip; \
	fi

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
