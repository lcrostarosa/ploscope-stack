// Generate sitemap.xml and robots.txt based on MDX blog posts and public routes
// Usage: node scripts/generate_sitemap.js

const fs = require('fs');
const path = require('path');

const glob = require('glob');

// Import logger utility
const { logDebug } = require('../utils/logger');

const FRONTEND_ROOT = __dirname.replace(/\/scripts$/, '');
const PUBLIC_DIR = path.join(FRONTEND_ROOT, 'public');
const BLOG_POSTS_DIR = path.join(FRONTEND_ROOT, 'pages', 'blog', 'posts');

const BASE_URL =
  process.env.SITEMAP_BASE_URL ||
  process.env.REACT_APP_PUBLIC_URL ||
  'http://localhost:3001';

function ensureDir(dirPath) {
  if (!fs.existsSync(dirPath)) {
    fs.mkdirSync(dirPath, { recursive: true });
  }
}

function extractMetaFromMDX(content) {
  // Naive extraction of meta fields from `export const meta = { ... }`
  const metaBlockMatch = content.match(
    /export\s+const\s+meta\s*=\s*\{([\s\S]*?)\}/m
  );
  const meta = {};
  if (metaBlockMatch) {
    const block = metaBlockMatch[1];
    const grab = key => {
      const single = block.match(new RegExp(`${key}\\s*:\\s*'([^']+)'`));
      if (single && single[1]) return single[1];
      const dbl = block.match(new RegExp(`${key}\\s*:\\s*"([^"]+)"`));
      return dbl && dbl[1] ? dbl[1] : undefined;
    };
    meta.slug = grab('slug');
    meta.title = grab('title');
    meta.date = grab('date');
  }
  return meta;
}

function iso(date) {
  try {
    return new Date(date).toISOString();
  } catch (_) {
    return new Date().toISOString();
  }
}

function buildUrl(loc, lastmod, changefreq = 'weekly', priority = '0.6') {
  return `  <url>\n    <loc>${loc}</loc>\n    <lastmod>${lastmod}</lastmod>\n    <changefreq>${changefreq}</changefreq>\n    <priority>${priority}</priority>\n  </url>`;
}

function main() {
  ensureDir(PUBLIC_DIR);

  const urls = [];

  // Static public pages
  const staticPaths = [
    '/',
    '/pricing',
    '/register',
    '/privacy',
    '/terms',
    '/cookies',
    '/faq',
    '/support',
  ];
  const nowIso = new Date().toISOString();
  staticPaths.forEach(p =>
    urls.push(buildUrl(`${BASE_URL}${p}`, nowIso, 'monthly', '0.5'))
  );

  // Blog posts from MDX
  const mdxFiles = glob.sync('*.mdx', { cwd: BLOG_POSTS_DIR, absolute: true });
  mdxFiles.forEach(file => {
    const content = fs.readFileSync(file, 'utf8');
    const meta = extractMetaFromMDX(content);
    const slug = meta.slug || path.basename(file, '.mdx');
    const last = meta.date || fs.statSync(file).mtime.toISOString();
    urls.push(buildUrl(`${BASE_URL}/blog/${slug}`, iso(last), 'weekly', '0.8'));
  });

  const xml =
    `<?xml version="1.0" encoding="UTF-8"?>\n` +
    `<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n` +
    urls.join('\n') +
    '\n</urlset>\n';

  fs.writeFileSync(path.join(PUBLIC_DIR, 'sitemap.xml'), xml, 'utf8');

  const robots = `User-agent: *\nAllow: /\n\nSitemap: ${BASE_URL}/sitemap.xml\n`;
  fs.writeFileSync(path.join(PUBLIC_DIR, 'robots.txt'), robots, 'utf8');

  logDebug(`Generated sitemap.xml and robots.txt using BASE_URL=${BASE_URL}`);
}

main();
