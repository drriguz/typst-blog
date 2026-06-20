use anyhow::Result;
use std::path::Path;
use tera::{Context, Tera};

pub fn load_templates(root: &Path) -> Result<Tera> {
    let template_dir = root.join("templates/**/*.html");
    let tera = Tera::new(
        template_dir
            .to_str()
            .ok_or_else(|| anyhow::anyhow!("Invalid template path"))?,
    )?;
    Ok(tera)
}

pub fn render_post(
    tera: &Tera,
    title: &str,
    date: &str,
    tags: &[String],
    lang: &str,
    summary: &str,
    author: &str,
    content: &str,
) -> Result<String> {
    let mut ctx = Context::new();
    ctx.insert("title", title);
    ctx.insert("date", date);
    ctx.insert("tags", tags);
    ctx.insert("lang", lang);
    ctx.insert("summary", summary);
    ctx.insert("author", author);
    ctx.insert("content", content);
    ctx.insert("root_path", "../../");
    let html = tera.render("post.html", &ctx)?;
    Ok(html)
}

pub fn render_index(
    tera: &Tera,
    posts: &[crate::metadata::PostMeta],
    page: usize,
    total_pages: usize,
) -> Result<String> {
    // Page 1: at index.html (depth 0). Page N>1: at page/N/index.html (depth 2).
    let root_path = if page == 1 { "" } else { "../../" };

    let mut ctx = Context::new();
    ctx.insert("posts", posts);
    ctx.insert("root_path", root_path);
    ctx.insert("lang", "en");
    insert_pagination_context(&mut ctx, page, total_pages, "page");
    let html = tera.render("index.html", &ctx)?;
    Ok(html)
}

pub fn render_tag_index(
    tera: &Tera,
    tag: &str,
    posts: &[crate::metadata::PostMeta],
    page: usize,
    total_pages: usize,
) -> Result<String> {
    // Page 1: at tags/<tag>/index.html (depth 2). Page N>1: at tags/<tag>/page/N/index.html (depth 4).
    let root_path = if page == 1 { "../../" } else { "../../../" };

    let mut ctx = Context::new();
    ctx.insert("tag", tag);
    ctx.insert("posts", posts);
    ctx.insert("root_path", root_path);
    ctx.insert("lang", "en");
    insert_pagination_context(&mut ctx, page, total_pages, "page");
    let html = tera.render("tag.html", &ctx)?;
    Ok(html)
}

/// Insert pagination context variables. `page_prefix` is the directory name for pages
/// (e.g. "page"), used to build relative links like `../3/index.html`.
fn insert_pagination_context(ctx: &mut Context, page: usize, total_pages: usize, page_prefix: &str) {
    ctx.insert("current_page", &page);
    ctx.insert("total_pages", &total_pages);
    ctx.insert("has_prev", &(page > 1));
    ctx.insert("has_next", &(page < total_pages));

    // Compute relative URLs from the current page's location.
    // Page 1 is at depth D, page N>1 is at depth D+2 (page/N/index.html).
    // From page 1: "page/X/index.html" for other pages, no prev.
    // From page N: "../X/index.html" for siblings, "../index.html" for page 1.
    if page > 1 {
        let prev_url = if page == 2 {
            "../index.html".to_string()
        } else {
            format!("../{}/index.html", page - 1)
        };
        ctx.insert("prev_url", &prev_url);
    }
    if page < total_pages {
        let next_url = if page == 1 {
            format!("{}/{}/index.html", page_prefix, page + 1)
        } else {
            format!("../{}/index.html", page + 1)
        };
        ctx.insert("next_url", &next_url);
    }

    // Page number links: each entry is a map with url and label
    let page_nums = page_numbers(page, total_pages);
    let page_links: Vec<std::collections::HashMap<&str, tera::Value>> = page_nums
        .iter()
        .map(|&p| {
            let mut m = std::collections::HashMap::new();
            m.insert("num", tera::to_value(p).unwrap());
            if p == 0 {
                // ellipsis
                m.insert("url", tera::to_value("").unwrap());
            } else if p == page {
                m.insert("url", tera::to_value("").unwrap());
            } else if page == 1 {
                if p == 1 {
                    m.insert("url", tera::to_value("index.html").unwrap());
                } else {
                    m.insert("url", tera::to_value(format!("{}/{}/index.html", page_prefix, p)).unwrap());
                }
            } else if p == 1 {
                m.insert("url", tera::to_value("../index.html").unwrap());
            } else {
                m.insert("url", tera::to_value(format!("../{}/index.html", p)).unwrap());
            }
            m
        })
        .collect();
    ctx.insert("page_links", &page_links);
}

/// Generate page number list with ellipsis, e.g. [1, 2, 3, 0, 9] where 0 = "..."
fn page_numbers(current: usize, total: usize) -> Vec<usize> {
    if total <= 7 {
        return (1..=total).collect();
    }
    let mut pages = vec![1];
    let start = if current > 3 { current - 1 } else { 2 };
    let end = if current < total - 2 {
        current + 1
    } else {
        total - 1
    };
    if start > 2 {
        pages.push(0); // ellipsis
    }
    for p in start..=end {
        pages.push(p);
    }
    if end < total - 1 {
        pages.push(0); // ellipsis
    }
    pages.push(total);
    pages
}

pub fn render_tags_all(
    tera: &Tera,
    tags_with_counts: &[(String, usize)],
) -> Result<String> {
    let tags: Vec<std::collections::HashMap<&str, tera::Value>> = tags_with_counts
        .iter()
        .map(|(name, count)| {
            let mut m = std::collections::HashMap::new();
            m.insert("name", tera::to_value(name).unwrap());
            m.insert("count", tera::to_value(count).unwrap());
            m
        })
        .collect();

    let mut ctx = Context::new();
    ctx.insert("tags", &tags);
    ctx.insert("root_path", "../");
    ctx.insert("lang", "en");
    let html = tera.render("tags-all.html", &ctx)?;
    Ok(html)
}
