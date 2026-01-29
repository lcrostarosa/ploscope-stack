import React from 'react';

type BlogMeta = {
  title?: string;
  date?: string;
  excerpt?: string;
  image?: string;
  imageUrl?: string;
  cover?: string;
  thumbnail?: string;
  imageAlt?: string;
  slug?: string;
};

export type BlogPost = {
  slug: string;
  title: string;
  date: string;
  excerpt?: string;
  component: React.ComponentType<Record<string, unknown>>;
  imageUrl?: string;
  imageAlt?: string;
};

// Require all MDX files under blog content directory
// Webpack's require.context will bundle these for the SPA
// eslint-disable-next-line
const mdxContext = (require as any).context('./posts', false, /\.mdx$/);

const mdxModules: Array<{
  slug: string;
  meta: BlogMeta;
  component: React.ComponentType<Record<string, unknown>>;
}> = mdxContext.keys().map((key: string) => {
  const mod = mdxContext(key);
  // eslint-disable-next-line
  const component = (mod as any).default as React.ComponentType<
    Record<string, unknown>
  >;
  // eslint-disable-next-line
  const meta = ((mod as any).meta || {}) as BlogMeta;
  const slug =
    (meta.slug as string) || key.replace(/^\.\//, '').replace(/\.mdx$/, '');
  return { slug, meta, component };
});

export const blogPosts: BlogPost[] = mdxModules
  .map(({ slug, meta, component }) => {
    const imageUrl =
      meta.image ||
      meta.imageUrl ||
      meta.cover ||
      meta.thumbnail ||
      '/og-preview.png';
    const imageAlt = meta.imageAlt || meta.title || slug;
    return {
      slug,
      title: meta.title || slug,
      date: meta.date || new Date().toISOString(),
      excerpt: meta.excerpt || '',
      component,
      imageUrl,
      imageAlt,
    } as BlogPost;
  })
  // Sort by date descending
  .sort((a, b) => (a.date < b.date ? 1 : -1));

export const findPostBySlug = (slug: string): BlogPost | undefined =>
  blogPosts.find(p => p.slug === slug);
