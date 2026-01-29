import React, { useState } from 'react';

// @ts-expect-error - react-helmet types not installed, relying on runtime only
import { Helmet } from 'react-helmet';

import './FAQPage.scss';

const FAQPage = () => {
  const [openSections, setOpenSections] = useState<Set<string>>(
    new Set<string>(['general', 'analysis', 'gameplay'])
  );

  const toggleSection = (sectionId: string) => {
    const newOpenSections = new Set(openSections);
    if (newOpenSections.has(sectionId)) {
      newOpenSections.delete(sectionId);
    } else {
      newOpenSections.add(sectionId);
    }
    setOpenSections(newOpenSections);
  };

  const faqData = {
    general: {
      title: 'General Questions',
      icon: '❓',
      questions: [
        {
          question: 'What is a PLO bomb pot analyzer?',
          answer:
            'A PLO bomb pot analyzer is a tool that calculates hand equities, EVs, and scoop probabilities in pot-limit Omaha hands where all players see the flop. PLOScope is the first analyzer built specifically for double board bomb pots, accounting for complex split scenarios and multi-way dynamics.',
        },
        {
          question: 'How is PLOScope different from other analyzers?',
          answer:
            "Most analyzers are built for heads-up GTO solutions or single board runouts. PLOScope is purpose-built for double board simulations, multi-way spots (up to 8 players), equity splits and scooping scenarios. It's the only analyzer that models how hands perform when both boards matter.",
        },
        {
          question: 'Is this a GTO analyzer?',
          answer:
            'Not exactly. PLOScope focuses on equity-based analysis and hand strength across boards, not strict Nash equilibrium ranges. It helps players build practical, exploit-ready strategies for bomb pots.',
        },
        {
          question: 'Is it legal to use?',
          answer:
            "Yes. PLOScope is a study and analysis tool. It's not a real-time assistant or RTA, and it's fully compliant with standard site policies for poker analyzers.",
        },
      ],
    },
    analysis: {
      title: 'Analysis Features & Capabilities',
      icon: '🔧',
      questions: [
        {
          question: 'Can I simulate full 6-way or 8-way bomb pots?',
          answer:
            'Yes. PLOScope supports up to 8 players per simulation. This makes it perfect for analyzing the real-world complexity of bomb pots in live or online PLO games.',
        },
        {
          question: 'Does it support custom ranges and board textures?',
          answer:
            'Absolutely. You can define custom preflop ranges, set specific board runouts, run simulations on paired, wet, or polarized textures, and simulate how blockers or redraws impact scoop potential.',
        },
        {
          question: 'How fast is it?',
          answer:
            'Most simulations complete in under 10 seconds, thanks to an optimized Monte Carlo engine designed for bomb pot math.',
        },
        {
          question: 'Can I use it on mobile?',
          answer:
            "Yes, PLOScope is fully responsive and works on desktop, tablet, and mobile devices. Whether you're on the couch or in the poker room, you can run bomb pot sims in seconds.",
        },
        {
          question: 'Is there a free trial?',
          answer:
            'We offer free sample simulations and limited access to explore the tool. Full sim capabilities require a subscription.',
        },
      ],
    },
    gameplay: {
      title: 'Game Rules & Formats',
      icon: '🎮',
      questions: [
        {
          question: 'What game formats is this for?',
          answer:
            'PLOScope is ideal for cash game bomb pots, double board bomb pot tournaments, WSOP events or private club games, and any format where all players see the flop and two boards are dealt.',
        },
        {
          question: 'How do Double Board Bomb Pots work?',
          answer:
            'In double board bomb pots, all players see the flop and two separate boards are dealt. Players can win on either board, and the pot is split if different players win on different boards. This creates complex equity scenarios that require specialized analysis.',
        },
        {
          question: 'What are the basic rules of PLO?',
          answer:
            "Pot-Limit Omaha (PLO) is a poker variant where each player receives 4 hole cards and must use exactly 2 of them combined with exactly 3 community cards to make the best 5-card hand. Betting is limited to the current pot size, and the game features more action and bigger pots than Texas Hold'em.",
        },
        {
          question: 'How do equity calculations work in bomb pots?',
          answer:
            "Equity in bomb pots considers the probability of winning on each board, the potential for splitting the pot, and the complex interactions between multiple players and two separate runouts. PLOScope's algorithms account for all possible outcomes and their probabilities.",
        },
      ],
    },
    technical: {
      title: 'Technical Details',
      icon: '⚙️',
      questions: [
        {
          question: 'What algorithms does PLOScope use?',
          answer:
            'PLOScope uses advanced Monte Carlo simulation techniques optimized for multi-way scenarios and double board calculations. The engine is specifically designed to handle the computational complexity of bomb pot equity calculations efficiently.',
        },
        {
          question: 'How accurate are the calculations?',
          answer:
            'PLOScope provides highly accurate equity calculations based on millions of simulated runouts. The Monte Carlo approach ensures statistical significance while maintaining fast computation times suitable for practical use.',
        },
        {
          question: 'Can I export my analysis results?',
          answer:
            'Yes, you can save and export your analysis results, including equity breakdowns, scoop probabilities, and hand comparisons. This allows you to build a library of analyzed spots for future reference.',
        },
        {
          question: 'Does PLOScope support different stack sizes?',
          answer:
            'Yes, PLOScope can analyze scenarios with different stack sizes and effective stacks, allowing you to understand how position and stack depth affect equity in bomb pot situations.',
        },
      ],
    },
  };

  return (
    <>
      <Helmet>
        <title>
          PLO Bomb Pot Analyzer FAQ - PLOScope | Double Board PLO Analysis
        </title>
        <meta
          name="description"
          content="Get answers to frequently asked questions about PLOScope, the first PLO bomb pot analyzer. Learn about double board bomb pots, PLO rules, analysis features, and how to use our advanced equity calculator."
        />
        <meta
          name="keywords"
          content="PLO bomb pot analyzer, double board PLO, pot limit omaha analyzer, PLO equity calculator, bomb pot analysis, PLO rules, poker analyzer, multi-way PLO"
        />
        <meta name="robots" content="index, follow" />
        <meta
          property="og:title"
          content="PLO Bomb Pot Analyzer FAQ - PLOScope"
        />
        <meta
          property="og:description"
          content="Comprehensive FAQ about PLOScope, the first PLO bomb pot analyzer. Learn about double board analysis, PLO rules, and analysis features."
        />
        <meta property="og:type" content="website" />
        <meta property="og:url" content={window.location.href} />
        <link rel="canonical" href={window.location.href} />
        <script type="application/ld+json">
          {JSON.stringify({
            '@context': 'https://schema.org',
            '@type': 'FAQPage',
            mainEntity: Object.values(faqData).flatMap(section =>
              section.questions.map(q => ({
                '@type': 'Question',
                name: q.question,
                acceptedAnswer: {
                  '@type': 'Answer',
                  text: q.answer,
                },
              }))
            ),
          })}
        </script>
      </Helmet>

      <div className="faq-page dark">
        <div className="faq-container">
          {/* Header */}
          <div className="faq-header">
            <h1 className="faq-title">Frequently Asked Questions</h1>
            <p className="faq-subtitle">
              Everything you need to know about PLOScope, PLO bomb pots, and
              advanced poker analysis
            </p>
          </div>

          {/* FAQ Sections */}
          <div className="faq-sections">
            {Object.entries(faqData).map(([sectionId, section]) => (
              <div key={sectionId} className="faq-section">
                <button
                  className={`faq-section-header ${openSections.has(sectionId) ? 'open' : ''}`}
                  onClick={() => toggleSection(sectionId)}
                >
                  <span className="section-icon">{section.icon}</span>
                  <h2 className="section-title">{section.title}</h2>
                  <span className="toggle-icon">
                    {openSections.has(sectionId) ? '−' : '+'}
                  </span>
                </button>

                {openSections.has(sectionId) && (
                  <div className="faq-questions">
                    {section.questions.map((item, index) => (
                      <div key={index} className="faq-item">
                        <h3 className="faq-question">{item.question}</h3>
                        <div className="faq-answer">
                          <p>{item.answer}</p>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            ))}
          </div>

          {/* Call to Action */}
          <div className="faq-cta">
            <h2>Ready to Start Analyzing?</h2>
            <p>
              Join thousands of PLO players using PLOScope to improve their bomb
              pot game
            </p>
            <div className="cta-buttons">
              <a href="/register" className="cta-button primary">
                Start Free Trial
              </a>
              <a href="/pricing" className="cta-button secondary">
                View Pricing
              </a>
            </div>
          </div>
        </div>
      </div>
    </>
  );
};

export default FAQPage;
