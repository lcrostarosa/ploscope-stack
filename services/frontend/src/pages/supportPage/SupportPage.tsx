import React, { useState } from 'react';

// @ts-expect-error - react-helmet types not installed, relying on runtime only
import { Helmet } from 'react-helmet';
import { Link } from 'react-router-dom';

import SearchIcon from '../../components/ui/icons/SearchIcon';
import './SupportPage.scss';

// Helper function to safely render content without dangerouslySetInnerHTML
const renderContent = (content: string) => {
  // Split content by HTML tags and create JSX elements
  const parts = content.split(/(<[^>]+>)/);
  const elements: React.ReactNode[] = [];

  for (let i = 0; i < parts.length; i++) {
    const part = parts[i];

    if (part.startsWith('<h3>') && part.endsWith('</h3>')) {
      const text = part.replace(/<\/?h3>/g, '');
      elements.push(<h3 key={i}>{text}</h3>);
    } else if (part.startsWith('<h4>') && part.endsWith('</h4>')) {
      const text = part.replace(/<\/?h4>/g, '');
      elements.push(<h4 key={i}>{text}</h4>);
    } else if (part.startsWith('<p>') && part.endsWith('</p>')) {
      const text = part.replace(/<\/?p>/g, '');
      elements.push(<p key={i}>{text}</p>);
    } else if (part.startsWith('<ul>') && part.endsWith('</ul>')) {
      const listContent = part.replace(/<\/?ul>/g, '');
      const listItems = listContent.split('<li>').filter(item => item.trim());
      const liElements = listItems
        .map((item, index) => {
          const cleanItem = item.replace(/<\/li>/g, '').trim();
          if (cleanItem) {
            // Handle <strong> tags within list items
            const strongParts = cleanItem.split(/(<strong>.*?<\/strong>)/);
            const strongElements = strongParts.map(
              (strongPart, strongIndex) => {
                if (
                  strongPart.startsWith('<strong>') &&
                  strongPart.endsWith('</strong>')
                ) {
                  const strongText = strongPart.replace(/<\/?strong>/g, '');
                  return <strong key={strongIndex}>{strongText}</strong>;
                }
                return strongPart;
              }
            );
            return <li key={index}>{strongElements}</li>;
          }
          return null;
        })
        .filter(Boolean);
      elements.push(<ul key={i}>{liElements}</ul>);
    } else if (part.startsWith('<ol>') && part.endsWith('</ol>')) {
      const listContent = part.replace(/<\/?ol>/g, '');
      const listItems = listContent.split('<li>').filter(item => item.trim());
      const liElements = listItems
        .map((item, index) => {
          const cleanItem = item.replace(/<\/li>/g, '').trim();
          if (cleanItem) {
            // Handle <strong> tags within list items
            const strongParts = cleanItem.split(/(<strong>.*?<\/strong>)/);
            const strongElements = strongParts.map(
              (strongPart, strongIndex) => {
                if (
                  strongPart.startsWith('<strong>') &&
                  strongPart.endsWith('</strong>')
                ) {
                  const strongText = strongPart.replace(/<\/?strong>/g, '');
                  return <strong key={strongIndex}>{strongText}</strong>;
                }
                return strongPart;
              }
            );
            return <li key={index}>{strongElements}</li>;
          }
          return null;
        })
        .filter(Boolean);
      elements.push(<ol key={i}>{liElements}</ol>);
    } else if (part.trim() && !part.startsWith('<') && !part.endsWith('>')) {
      // Handle plain text with <strong> tags
      const strongParts = part.split(/(<strong>.*?<\/strong>)/);
      const textElements = strongParts.map((textPart, textIndex) => {
        if (textPart.startsWith('<strong>') && textPart.endsWith('</strong>')) {
          const strongText = textPart.replace(/<\/?strong>/g, '');
          return <strong key={textIndex}>{strongText}</strong>;
        }
        return textPart;
      });
      if (textElements.some(el => typeof el !== 'string' || el.trim())) {
        elements.push(<span key={i}>{textElements}</span>);
      }
    }
  }

  return elements;
};

const SupportPage = () => {
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('all');

  const helpArticles = [
    {
      id: 'getting-started',
      title: 'Getting Started with PLOScope',
      category: 'getting-started',
      description: 'Learn the basics of using PLOScope for PLO analysis',
      content: `
        <h3>Welcome to PLOScope!</h3>
        <p>PLOScope is a powerful PLO (Pot Limit Omaha) analysis tool designed specifically for bomb pots and multi-way scenarios. Here's how to get started:</p>
        
        <h4>1. Choose Your Mode</h4>
        <ul>
          <li><strong>Live Mode:</strong> Deal hands and analyze them in real-time</li>
          <li><strong>Spot Mode:</strong> Analyze specific poker situations</li>
        </ul>
        
        <h4>2. Set Up Your Hand</h4>
        <p>Configure player positions, stack sizes, and hole cards. You can randomize hands or input specific cards.</p>
        
        <h4>3. Analyze Results</h4>
        <p>View equity calculations, hand strength analysis, and strategic insights.</p>
      `,
      tags: ['beginner', 'tutorial', 'setup'],
    },
    {
      id: 'live-mode-guide',
      title: 'Live Mode Guide',
      category: 'modes',
      description: 'How to use Live Mode for real-time hand analysis',
      content: `
        <h3>Live Mode - Real-time Hand Analysis</h3>
        <p>Live Mode is perfect for analyzing hands as they happen or for studying specific scenarios.</p>
        
        <h4>Key Features:</h4>
        <ul>
          <li><strong>Deal Hand:</strong> Generate random hands for analysis</li>
          <li><strong>Study This Spot:</strong> Copy current hand to Spot Mode for detailed analysis</li>
          <li><strong>Next Hand:</strong> Generate a new hand with the same configuration</li>
        </ul>
        
        <h4>Workflow:</h4>
        <ol>
          <li>Set up your game configuration (blinds, stack sizes)</li>
          <li>Click "Deal Cards" to generate a hand</li>
          <li>Review the hand and use "Study This Spot" for detailed analysis</li>
          <li>Practice with different scenarios</li>
        </ol>
      `,
      tags: ['live-mode', 'tutorial', 'workflow'],
    },
    {
      id: 'spotMode-mode-guide',
      title: 'Spot Mode Guide',
      category: 'modes',
      description: 'Master Spot Mode for detailed hand analysis',
      content: `
        <h3>Spot Mode - Detailed Hand Analysis</h3>
        <p>Spot Mode provides comprehensive analysis of specific poker situations with step-by-step setup.</p>
        
        <h4>Setup Process:</h4>
        <ol>
          <li><strong>Game Configuration:</strong> Set blinds, stack sizes, and player positions</li>
          <li><strong>Player Hands:</strong> Input hole cards for each player</li>
          <li><strong>Board Cards:</strong> Set community cards (flop, turn, river)</li>
          <li><strong>Pot & Betting:</strong> Configure pot size and current action</li>
        </ol>
        
        <h4>Analysis Features:</h4>
        <ul>
          <li>Equity calculations for all players</li>
          <li>Hand strength analysis</li>
          <li>Strategic recommendations</li>
          <li>Range analysis tools</li>
        </ul>
      `,
      tags: ['spotMode-mode', 'analysis', 'setup'],
    },
    {
      id: 'equity-calculations',
      title: 'Understanding Equity Calculations',
      category: 'concepts',
      description: 'Learn how equity is calculated and what it means',
      content: `
        <h3>Equity Calculations Explained</h3>
        <p>Equity is a fundamental concept in poker that represents your share of the pot.</p>
        
        <h4>What is Equity?</h4>
        <p>Equity is the percentage of the pot that belongs to you based on your current hand strength and the probability of improving.</p>
        
        <h4>How PLOScope Calculates Equity:</h4>
        <ul>
          <li><strong>Monte Carlo Simulation:</strong> Runs thousands of simulations to calculate accurate equity</li>
          <li><strong>Board Runouts:</strong> Considers all possible future community cards</li>
          <li><strong>Hand Rankings:</strong> Uses standard poker hand rankings</li>
          <li><strong>Split Scenarios:</strong> Accounts for pot splits in multi-way situations</li>
        </ul>
        
        <h4>Understanding the Results:</h4>
        <ul>
          <li><strong>High Equity (>60%):</strong> Strong hand, consider aggressive play</li>
          <li><strong>Medium Equity (40-60%):</strong> Moderate strength, play carefully</li>
          <li><strong>Low Equity (<40%):</strong> Weak hand, consider folding</li>
        </ul>
      `,
      tags: ['equity', 'calculations', 'theory'],
    },
    {
      id: 'bomb-pot-strategy',
      title: 'Bomb Pot Strategy Guide',
      category: 'strategy',
      description: 'Strategic considerations for bomb pot play',
      content: `
        <h3>Bomb Pot Strategy</h3>
        <p>Bomb pots present unique strategic challenges that require special consideration.</p>
        
        <h4>Bomb Pot Characteristics:</h4>
        <ul>
          <li><strong>Large Pots:</strong> Starting pot is already significant</li>
          <li><strong>Multi-way Action:</strong> Often involves 4+ players</li>
          <li><strong>Position Matters:</strong> Later position is more valuable</li>
          <li><strong>Draw-Heavy:</strong> Many hands have drawing potential</li>
        </ul>
        
        <h4>Strategic Principles:</h4>
        <ul>
          <li><strong>Play Strong Hands:</strong> Focus on hands with good equity</li>
          <li><strong>Position Awareness:</strong> Be more aggressive in position</li>
          <li><strong>Pot Control:</strong> Avoid over-committing with marginal hands</li>
          <li><strong>Draw Value:</strong> Consider the value of drawing hands</li>
        </ul>
        
        <h4>Common Mistakes:</h4>
        <ul>
          <li>Playing too many hands preflop</li>
          <li>Not considering position</li>
          <li>Overvaluing weak pairs</li>
          <li>Ignoring pot odds</li>
        </ul>
      `,
      tags: ['bomb-pots', 'strategy', 'multi-way'],
    },
    {
      id: 'troubleshooting',
      title: 'Troubleshooting Common Issues',
      category: 'help',
      description: 'Solutions to common problems and issues',
      content: `
        <h3>Troubleshooting Guide</h3>
        <p>Common issues and their solutions.</p>
        
        <h4>Performance Issues:</h4>
        <ul>
          <li><strong>Slow Calculations:</strong> Try reducing the number of players or simplifying the scenario</li>
          <li><strong>Browser Freezing:</strong> Close other tabs and refresh the page</li>
          <li><strong>Memory Issues:</strong> Clear browser cache and cookies</li>
        </ul>
        
        <h4>Calculation Errors:</h4>
        <ul>
          <li><strong>Invalid Hand:</strong> Ensure all cards are valid and unique</li>
          <li><strong>Missing Cards:</strong> Complete all required card inputs</li>
          <li><strong>Stack Size Issues:</strong> Verify stack sizes are positive numbers</li>
        </ul>
        
        <h4>Getting Help:</h4>
        <ul>
          <li>Check this knowledge base for detailed guides</li>
          <li>Use the live chat widget for immediate assistance</li>
          <li>Submit a support ticket for complex issues</li>
        </ul>
      `,
      tags: ['troubleshooting', 'help', 'issues'],
    },
  ];

  const categories = [
    { id: 'all', name: 'All Articles', icon: '📚' },
    { id: 'getting-started', name: 'Getting Started', icon: '🚀' },
    { id: 'modes', name: 'Game Modes', icon: '🎮' },
    { id: 'concepts', name: 'Poker Concepts', icon: '🧠' },
    { id: 'strategy', name: 'Strategy', icon: '🎯' },
    { id: 'help', name: 'Help & Support', icon: '❓' },
  ];

  const filteredArticles = helpArticles.filter(article => {
    const matchesSearch =
      article.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
      article.description.toLowerCase().includes(searchQuery.toLowerCase()) ||
      article.tags.some(tag =>
        tag.toLowerCase().includes(searchQuery.toLowerCase())
      );
    const matchesCategory =
      selectedCategory === 'all' || article.category === selectedCategory;
    return matchesSearch && matchesCategory;
  });

  const [expandedArticle, setExpandedArticle] = useState<string | null>(null);

  const toggleArticle = (articleId: string) => {
    setExpandedArticle(expandedArticle === articleId ? null : articleId);
  };

  return (
    <div className="support-page dark">
      <Helmet>
        <title>Support & Help Center - PLOScope</title>
        <meta
          name="description"
          content="Get help with PLOScope. Browse help articles, tutorials, and guides for all game modes and features."
        />
      </Helmet>

      <div className="support-container">
        {/* Header */}
        <div className="support-header">
          <div className="header-content">
            <h1>🎯 Support & Help Center</h1>
            <p>
              Find answers to your questions and learn how to use PLOScope
              effectively
            </p>
          </div>
          <div className="header-actions">
            <Link to="/app/live" className="back-btn">
              ← Back to App
            </Link>
          </div>
        </div>

        {/* Search and Filters */}
        <div className="search-filters">
          <div className="search-box">
            <input
              type="text"
              placeholder="Search help articles..."
              value={searchQuery}
              onChange={e => setSearchQuery(e.target.value)}
              className="search-input"
            />
            <SearchIcon className="search-icon" />
          </div>

          <div className="category-filters">
            {categories.map(category => (
              <button
                key={category.id}
                onClick={() => setSelectedCategory(category.id)}
                className={`category-filter ${selectedCategory === category.id ? 'active' : ''}`}
              >
                <span className="category-icon">{category.icon}</span>
                {category.name}
              </button>
            ))}
          </div>
        </div>

        {/* Quick Actions */}
        <div className="quick-actions">
          <h2>Quick Actions</h2>
          <div className="action-cards">
            <a href="mailto:support@ploscope.com" className="action-card">
              <div className="action-icon">📧</div>
              <h3>Email Support</h3>
              <p>Send us a detailed message</p>
            </a>
            <button
              onClick={() => (window.location.href = '/app/live')}
              className="action-card"
            >
              <div className="action-icon">💬</div>
              <h3>Live Chat</h3>
              <p>Get instant help via chat</p>
            </button>
            <a href="/faq" className="action-card">
              <div className="action-icon">❓</div>
              <h3>FAQ</h3>
              <p>Browse frequently asked questions</p>
            </a>
          </div>
        </div>

        {/* Help Articles */}
        <div className="help-articles">
          <h2>Help Articles</h2>
          <div className="articles-grid">
            {filteredArticles.map(article => (
              <div key={article.id} className="article-card">
                <div
                  className="article-header"
                  onClick={() => toggleArticle(article.id)}
                >
                  <div className="article-info">
                    <h3>{article.title}</h3>
                    <p>{article.description}</p>
                    <div className="article-tags">
                      {article.tags.map(tag => (
                        <span key={tag} className="tag">
                          {tag}
                        </span>
                      ))}
                    </div>
                  </div>
                  <div className="expand-icon">
                    {expandedArticle === article.id ? '−' : '+'}
                  </div>
                </div>

                {expandedArticle === article.id && (
                  <div className="article-content">
                    {renderContent(article.content)}
                  </div>
                )}
              </div>
            ))}
          </div>
        </div>

        {/* Contact Section */}
        <div className="contact-section">
          <h2>Still Need Help?</h2>
          <p>
            Our support team is here to help you get the most out of PLOScope.
          </p>
          <div className="contact-options">
            <a href="mailto:support@ploscope.com" className="contact-option">
              <div className="contact-icon">📧</div>
              <div>
                <h3>Email Support</h3>
                <p>support@ploscope.com</p>
              </div>
            </a>
            <button
              onClick={() => (window.location.href = '/app/live')}
              className="contact-option"
            >
              <div className="contact-icon">💬</div>
              <div>
                <h3>Live Chat</h3>
                <p>Available 24/7</p>
              </div>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default SupportPage;
