import React from 'react';

import { useParams, Link } from 'react-router-dom';

import { findPostBySlug } from './posts';
import './Blog.scss';

const BlogPost: React.FC = () => {
  const { slug } = useParams<{ slug: string }>();
  const post = slug ? findPostBySlug(slug) : undefined;

  if (!post) {
    return (
      <div className="page blog-post-page">
        <div className="empty-state">
          <h2>Post not found</h2>
          <p>The blog post you are looking for does not exist.</p>
          <Link to="/blog" className="btn btn-secondary">
            Back to Blog
          </Link>
        </div>
      </div>
    );
  }

  const MDXComponent = post.component;

  return (
    <div className="page blog-post-page">
      <nav className="breadcrumbs">
        <Link to="/">Home</Link>
        <span>/</span>
        <Link to="/blog">Blog</Link>
        <span>/</span>
        <span>{post.title}</span>
      </nav>

      <article className="blog-article">
        <header className="article-header">
          <h1>{post.title}</h1>
          <div className="article-meta">
            {new Date(post.date).toLocaleDateString()}
          </div>
        </header>

        <section className="article-content">
          <MDXComponent />
        </section>

        <section className="article-cta">
          <h3>Study this with PLOScope</h3>
          <ul>
            <li>
              Build and simulate realistic spots in{' '}
              <Link to="/app/spot">Spot Mode</Link>
            </li>
            <li>Save, review, and compare lines in Spot Mode</li>
          </ul>
          <div className="cta-actions">
            <Link to="/pricing" className="btn btn-primary">
              Sign up and get started
            </Link>
          </div>
        </section>
      </article>
    </div>
  );
};

export default BlogPost;
