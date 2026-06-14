use anyhow::{Context, Result};
use std::path::{Path, PathBuf};
use std::process::Command;

use crate::metadata::{self, PostMeta};
use crate::template;

pub fn build_site(root: &Path) -> Result<()> {
    let posts_dir = root.join("src").join("posts");
    let output_dir = root.join("output");

    if !posts_dir.exists() {
        anyhow::bail!("No src/posts/ directory found. Create a post first with `typst-blog new`.");
    }

    // Collect all posts
    let mut posts = discover_posts(&posts_dir)?;
    if posts.is_empty() {
        println!("No posts found in src/posts/");
        return Ok(());
    }

    // Sort by date descending
    posts.sort_by(|a, b| b.date.cmp(&a.date));

    // Prepare output directory
    if output_dir.exists() {
        std::fs::remove_dir_all(&output_dir)?;
    }
    std::fs::create_dir_all(&output_dir)?;

    // Load HTML templates
    let tera = template::load_templates(root)?;

    // Build each post
    for post in &posts {
        let post_source_dir = posts_dir.join(&post.source_dir);
        let post_output_dir = output_dir.join("posts").join(&post.slug);
        std::fs::create_dir_all(&post_output_dir)?;

        let typ_source = post_source_dir.join("post.typ");

        if typ_source.exists() {
            println!("[typst] Compiling {} ...", post.title);

            // 1. Compile PDF
            match run_typst(&typ_source, root, "pdf") {
                Ok(()) => {
                    let pdf_path = typ_source.with_extension("pdf");
                    if pdf_path.exists() {
                        std::fs::copy(&pdf_path, post_output_dir.join("post.pdf"))?;
                        let _ = std::fs::remove_file(&pdf_path);
                        println!("  -> PDF generated.");
                    }
                }
                Err(e) => eprintln!("  -> PDF failed: {}.", e),
            }

            // 2. Compile SVG (one per page) → embed in HTML
            match run_typst_svg(&typ_source, root, &post_source_dir) {
                Ok(svg_pages) => {
                    let svg_content = svg_pages.join("\n");
                    let full_html = template::render_post(
                        &tera,
                        &post.title,
                        &post.date,
                        &post.tags,
                        &post.lang,
                        &post.summary,
                        &svg_content,
                    )?;
                    std::fs::write(post_output_dir.join("index.html"), &full_html)?;
                    println!("  -> HTML generated ({} pages).", svg_pages.len());
                }
                Err(e) => eprintln!("  -> SVG failed: {}.", e),
            }
        }

        // 3. Copy post-local images
        let images_dir = post_source_dir.join("images");
        if images_dir.exists() {
            let images_output = post_output_dir.join("images");
            copy_dir_recursive(&images_dir, &images_output)?;
        }

        println!("  -> Done: posts/{}/", post.slug);
    }

    // Generate index page
    println!("[index] Generating index page ...");
    let index_html = template::render_index(&tera, &posts)?;
    std::fs::write(output_dir.join("index.html"), &index_html)?;

    // Generate tag pages
    println!("[tags] Generating tag pages ...");
    generate_tag_pages(&tera, &posts, &output_dir)?;

    // Copy static assets
    let static_dir = root.join("static");
    if static_dir.exists() {
        copy_dir_recursive(&static_dir, &output_dir)?;
    }

    println!("\nBuild complete! Output: {}", output_dir.display());
    println!("Run `typst-blog serve` to preview locally.");
    Ok(())
}

fn discover_posts(posts_dir: &Path) -> Result<Vec<PostMeta>> {
    let mut posts = Vec::new();

    for entry in std::fs::read_dir(posts_dir)? {
        let entry = entry?;
        let path = entry.path();
        if path.is_dir() {
            let typ_file = path.join("post.typ");

            if typ_file.exists() {
                match metadata::parse_metadata(&typ_file) {
                    Ok(m) => posts.push(m),
                    Err(e) => eprintln!("Warning: Failed to parse {}: {}", path.display(), e),
                }
            }
        }
    }

    Ok(posts)
}

fn generate_tag_pages(tera: &tera::Tera, posts: &[PostMeta], output_dir: &Path) -> Result<()> {
    use std::collections::HashMap;
    let mut tag_map: HashMap<String, Vec<PostMeta>> = HashMap::new();

    for post in posts {
        for tag in &post.tags {
            tag_map.entry(tag.clone()).or_default().push(post.clone());
        }
    }

    for (tag, tag_posts) in &tag_map {
        let tag_dir = output_dir.join("tags").join(tag);
        std::fs::create_dir_all(&tag_dir)?;
        let html = template::render_tag_index(tera, tag, tag_posts)?;
        std::fs::write(tag_dir.join("index.html"), html)?;
    }

    // Generate tags-all page
    let tags_with_counts: Vec<(String, usize)> = tag_map
        .iter()
        .map(|(name, posts)| (name.clone(), posts.len()))
        .collect();
    let tags_all_html = template::render_tags_all(tera, &tags_with_counts)?;
    let tags_all_dir = output_dir.join("tags-all");
    std::fs::create_dir_all(&tags_all_dir)?;
    std::fs::write(tags_all_dir.join("index.html"), tags_all_html)?;

    Ok(())
}

fn run_typst(typ_path: &Path, project_root: &Path, format: &str) -> Result<()> {
    let output_path = typ_path.with_extension(format);

    // Use modified Typst for SVG (selectable text), system Typst for PDF
    let typst_cmd = if format == "svg" {
        // Check for modified Typst binary in project root
        let modified = project_root.join("typst-modified");
        if modified.exists() {
            modified
        } else {
            PathBuf::from("typst")
        }
    } else {
        PathBuf::from("typst")
    };

    let status = Command::new(typst_cmd)
        .arg("compile")
        .arg("--root")
        .arg(project_root)
        .arg("--format")
        .arg(format)
        .arg(typ_path)
        .arg(&output_path)
        .status()
        .context("Failed to run typst. Is typst installed?")?;

    if !status.success() {
        anyhow::bail!("Typst {} compilation failed for {}", format, typ_path.display());
    }

    Ok(())
}

/// Compile Typst to SVG (one file per page) and return the SVG contents.
fn run_typst_svg(typ_path: &Path, project_root: &Path, post_dir: &Path) -> Result<Vec<String>> {
    // Use {p} for page numbers: post-1.svg, post-2.svg, etc.
    let output_pattern = post_dir.join("post-{p}.svg");
    let output_str = output_pattern.to_str().unwrap();

    // Use modified Typst for SVG (selectable text)
    let typst_cmd = {
        let modified = project_root.join("typst-modified");
        if modified.exists() {
            modified
        } else {
            PathBuf::from("typst")
        }
    };

    let status = Command::new(typst_cmd)
        .arg("compile")
        .arg("--root")
        .arg(project_root)
        .arg("--format")
        .arg("svg")
        .arg(typ_path)
        .arg(output_str)
        .status()
        .context("Failed to run typst. Is typst installed?")?;

    if !status.success() {
        anyhow::bail!("Typst SVG compilation failed for {}", typ_path.display());
    }

    // Collect generated SVG files in order
    let mut pages = Vec::new();
    let mut i = 1;
    loop {
        let svg_path = post_dir.join(format!("post-{}.svg", i));
        if svg_path.exists() {
            let content = std::fs::read_to_string(&svg_path)?;
            pages.push(content);
            std::fs::remove_file(&svg_path)?;
            i += 1;
        } else {
            break;
        }
    }

    if pages.is_empty() {
        anyhow::bail!("No SVG pages generated for {}", typ_path.display());
    }

    Ok(pages)
}

fn copy_dir_recursive(src: &Path, dst: &Path) -> Result<()> {
    if !dst.exists() {
        std::fs::create_dir_all(dst)?;
    }

    for entry in std::fs::read_dir(src)? {
        let entry = entry?;
        let src_path = entry.path();
        let dst_path = dst.join(entry.file_name());

        if src_path.is_dir() {
            copy_dir_recursive(&src_path, &dst_path)?;
        } else {
            std::fs::copy(&src_path, &dst_path)?;
        }
    }

    Ok(())
}
