use anyhow::{Context, Result};
use std::path::Path;

/// Site-wide settings loaded from `blog.toml` at the project root.
#[derive(Debug, Clone, Default, serde::Deserialize)]
pub struct BlogConfig {
    /// Author name shown in each post's title block and metadata.
    /// When empty, posts fall back to their own `author` parameter.
    #[serde(default)]
    pub author: String,
}

impl BlogConfig {
    pub fn load(root: &Path) -> Result<Self> {
        let path = root.join("blog.toml");
        if !path.exists() {
            return Ok(Self::default());
        }

        let content = std::fs::read_to_string(&path)
            .with_context(|| format!("Failed to read {}", path.display()))?;
        let config: BlogConfig = toml::from_str(&content)
            .with_context(|| format!("Failed to parse {}", path.display()))?;
        Ok(config)
    }
}
