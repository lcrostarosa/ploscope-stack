import React from 'react';

import { Link } from 'react-router-dom';

import { blogPosts } from './posts';
import './Blog.scss';

const BlogList: React.FC = () => {
  return (
    <div className="page blog-list-page">
      <header className="page-header">
        <h1>Blog</h1>
        <p className="page-subtitle">
          Product updates, strategy primers, and PLO insights
        </p>
      </header>

      <div className="card-grid">
        {blogPosts.map(post => (
          <article key={post.slug} className="post-card">
            <Link
              to={`/blog/${post.slug}`}
              className="post-cover"
              aria-label={`Open ${post.title}`}
            >
              <img
                src={post.imageUrl}
                alt={post.imageAlt || post.title}
                loading="lazy"
              />
            </Link>
            <div className="post-body">
              <h2 className="post-title">
                <Link to={`/blog/${post.slug}`}>{post.title}</Link>
              </h2>
              <div className="post-meta">
                {new Date(post.date).toLocaleDateString()}
              </div>
              {post.excerpt ? (
                <p className="post-excerpt">{post.excerpt}</p>
              ) : null}
              <div className="post-actions">
                <Link
                  to={`/blog/${post.slug}`}
                  className="btn btn-primary"
                  aria-label={`Read ${post.title}`}
                >
                  Read more
                </Link>
              </div>
            </div>
          </article>
        ))}
      </div>
    </div>
  );
};

export default BlogList;
