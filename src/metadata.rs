use anyhow::{Context, Result};
use regex::Regex;
use std::path::Path;

#[derive(Debug, Clone, serde::Serialize)]
pub struct PostMeta {
    pub title: String,
    pub date: String,
    pub tags: Vec<String>,
    pub lang: String,
    pub summary: String,
    pub slug: String,
    pub source_dir: String,
}

pub fn parse_metadata(typ_path: &Path) -> Result<PostMeta> {
    let content = std::fs::read_to_string(typ_path)
        .with_context(|| format!("Failed to read {}", typ_path.display()))?;

    let title = extract_typst_param(&content, "title").unwrap_or_else(|| "Untitled".to_string());
    let date = extract_typst_param(&content, "date").unwrap_or_else(|| "1970-01-01".to_string());
    let tags_str = extract_typst_param(&content, "tags").unwrap_or_default();
    let lang = extract_typst_param(&content, "lang").unwrap_or_else(|| "en".to_string());
    let summary = extract_typst_param(&content, "summary").unwrap_or_default();

    let tags = parse_typst_tags(&tags_str);

    let source_dir = typ_path
        .parent()
        .and_then(|p| p.file_name())
        .and_then(|n| n.to_str())
        .unwrap_or("unknown")
        .to_string();

    let slug = derive_slug(&source_dir);

    Ok(PostMeta {
        title,
        date,
        tags,
        lang,
        summary,
        slug,
        source_dir,
    })
}

fn extract_typst_param(content: &str, param: &str) -> Option<String> {
    // Special handling for tags array: tags: ("math", "algorithms")
    if param == "tags" {
        let pattern = r#"tags\s*:\s*\(([^)]*)\)"#;
        let re = Regex::new(pattern).ok()?;
        let caps = re.captures(content)?;
        return Some(caps[1].to_string());
    }

    // Special handling for summary which uses Typst content blocks: summary: [...]
    if param == "summary" {
        let pattern = format!(r#"summary\s*:\s*\[(.*?)\]"#,);
        let re = Regex::new(&pattern).ok()?;
        if let Some(caps) = re.captures(content) {
            // Clean up Typst markup for plain text
            let text = caps[1]
                .replace("---", "—")
                .replace("--", "–")
                .replace("\\[", "[")
                .replace("\\]", "]");
            // Strip Typst markup like *bold*, _italic_, #function()
            let cleaned = strip_typst_markup(&text);
            return Some(cleaned.trim().to_string());
        }
    }

    // Default: match quoted string "..."
    let pattern = format!(
        r#"{}\s*:\s*"((?:[^"\\]|\\.)*)""#,
        regex::escape(param)
    );
    let re = Regex::new(&pattern).ok()?;
    let caps = re.captures(content)?;
    Some(caps[1].replace("\\\"", "\"").replace("\\\\", "\\"))
}

fn strip_typst_markup(text: &str) -> String {
    let mut result = String::new();
    let chars: Vec<char> = text.chars().collect();
    let mut i = 0;
    while i < chars.len() {
        match chars[i] {
            // Skip *bold* markers
            '*' => { i += 1; }
            // Skip _italic_ markers
            '_' => { i += 1; }
            // Skip #function(...) calls — take the argument text
            '#' => {
                // Skip until we find the content
                while i < chars.len() && chars[i] != '[' && chars[i] != '(' && !chars[i].is_alphanumeric() {
                    i += 1;
                }
                // If it's a function with content in brackets, skip the function name
                if i < chars.len() && chars[i].is_alphanumeric() {
                    while i < chars.len() && chars[i] != '[' && chars[i] != '(' {
                        i += 1;
                    }
                }
            }
            _ => {
                result.push(chars[i]);
                i += 1;
            }
        }
    }
    result
}

fn parse_typst_tags(tags_str: &str) -> Vec<String> {
    if tags_str.is_empty() {
        return vec![];
    }
    let re = Regex::new(r#""([^"]*)""#).unwrap();
    re.captures_iter(tags_str)
        .map(|caps| caps[1].to_string())
        .collect()
}

fn derive_slug(dir_name: &str) -> String {
    let date_prefix = Regex::new(r"^\d{4}-\d{2}-\d{2}-").unwrap();
    date_prefix.replace(dir_name, "").to_string()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_extract_typst_param() {
        let content = r#"#show: blog-post.with(
  title: "Understanding FFT",
  date: "2025-12-01",
  tags: ("math", "algorithms", "signal-processing"),
  lang: "en",
  summary: "An intro to FFT",
)"#;
        assert_eq!(
            extract_typst_param(content, "title"),
            Some("Understanding FFT".into())
        );
        assert_eq!(
            extract_typst_param(content, "date"),
            Some("2025-12-01".into())
        );
        assert_eq!(extract_typst_param(content, "lang"), Some("en".into()));
    }

    #[test]
    fn test_parse_typst_tags() {
        assert_eq!(
            parse_typst_tags(r#"("math", "algorithms")"#),
            vec!["math", "algorithms"]
        );
        assert_eq!(parse_typst_tags(r#"("rust",)"#), vec!["rust"]);
        assert_eq!(parse_typst_tags(""), Vec::<String>::new());
    }

    #[test]
    fn test_derive_slug() {
        assert_eq!(derive_slug("2025-12-01-hello-world"), "hello-world");
        assert_eq!(derive_slug("no-date-prefix"), "no-date-prefix");
    }
}
