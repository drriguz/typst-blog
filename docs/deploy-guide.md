# Deployment Guide

Step-by-step guide to deploy the blog to your own server.

## Prerequisites

- A Linux server (Ubuntu/Debian recommended)
- Domain name pointing to your server (optional)
- Nginx or Apache installed (for serving static files)

## Step 1: Create deploy user on server

SSH into your server as root:

```bash
ssh root@your-server-ip
```

Create a dedicated user for deployment:

```bash
# Create user
adduser deploy

# Add to www-data group (for web directory access)
usermod -aG www-data deploy
```

## Step 2: Create web directory

```bash
# Create directory for the blog
mkdir -p /var/www/blog

# Set ownership
chown -R deploy:www-data /var/www/blog

# Set permissions
chmod -R 755 /var/www/blog
```

## Step 3: Configure Nginx

Copy the optimized config:

```bash
# Copy config file (from this repo)
scp docs/nginx.conf root@your-server:/etc/nginx/sites-available/blog

# Or create manually
nano /etc/nginx/sites-available/blog
```

See [nginx.conf](nginx.conf) for the full optimized config with:
- SSL/HTTPS with HTTP/2
- Gzip compression
- Static asset caching (1 year)
- Security headers
- Clean URLs (no .html extension)

Enable the site:

```bash
ln -s /etc/nginx/sites-available/blog /etc/nginx/sites-enabled/
nginx -t  # Test config
systemctl reload nginx
```

## Step 4: Generate SSH key on your local machine

On your local machine (not the server):

```bash
# Generate SSH key pair
ssh-keygen -t ed25519 -C "github-deploy-blog" -f ~/.ssh/blog-deploy

# This creates two files:
# ~/.ssh/blog-deploy      (private key - keep secret!)
# ~/.ssh/blog-deploy.pub  (public key - copy to server)
```

## Step 5: Copy public key to server

```bash
# Copy public key to server
ssh-copy-id -i ~/.ssh/blog-deploy.pub deploy@your-server-ip

# Test SSH connection
ssh -i ~/.ssh/blog-deploy deploy@your-server-ip
```

## Step 6: Configure GitHub Secrets

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add each secret:

| Name | Value |
|------|-------|
| `DEPLOY_HOST` | `your-server-ip` or `your-domain.com` |
| `DEPLOY_PORT` | `22` (or your custom SSH port) |
| `DEPLOY_USER` | `deploy` |
| `DEPLOY_PATH` | `/var/www/blog/` |
| `DEPLOY_KEY` | Contents of `~/.ssh/blog-deploy` (private key) |

To get the private key content:

```bash
cat ~/.ssh/blog-deploy
```

Copy the entire output including `-----BEGIN OPENSSH PRIVATE KEY-----` and `-----END OPENSSH PRIVATE KEY-----`.

## Step 7: Test deployment

Push to main branch:

```bash
git add .
git commit -m "Initial commit"
git push origin main
```

Go to **Actions** tab in GitHub to watch the deployment.

## Optional: Enable HTTPS with Let's Encrypt

```bash
# Install Certbot
apt install certbot python3-certbot-nginx

# Get certificate
certbot --nginx -d your-domain.com

# Auto-renewal is set up automatically
```

## Optional: Configure firewall

```bash
# Allow SSH, HTTP, HTTPS
ufw allow OpenSSH
ufw allow 'Nginx Full'
ufw enable
```

## Manual deployment (alternative)

If you prefer to deploy manually without GitHub Actions:

```bash
# On your local machine
make build
rsync -avzr --delete -e "ssh -i ~/.ssh/blog-deploy" output/ deploy@your-server:/var/www/blog/
```

Or set up a Makefile shortcut:

```bash
# Add to .env or export
export DEPLOY_TARGET=deploy@your-server:/var/www/blog/

# Then deploy with
make deploy
```

## Troubleshooting

### Permission denied
```bash
# Check SSH key permissions
chmod 600 ~/.ssh/blog-deploy
chmod 644 ~/.ssh/blog-deploy.pub

# Check server directory permissions
ls -la /var/www/blog/
```

### Connection refused
```bash
# Check SSH is running on server
systemctl status sshd

# Check firewall
ufw status
```

### Files not updating
```bash
# Check rsync is working
rsync -avzr --delete -e "ssh -i ~/.ssh/blog-deploy" output/ deploy@your-server:/var/www/blog/

# Check Nginx is serving the right directory
cat /etc/nginx/sites-enabled/blog
```
