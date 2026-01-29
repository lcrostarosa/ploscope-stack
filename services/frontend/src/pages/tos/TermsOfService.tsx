import React from 'react';

const TermsOfService = () => {
  return (
    <div className="min-h-screen bg-gray-900 text-white">
      <div className="container mx-auto px-4 py-8">
        <div className="max-w-4xl mx-auto">
          {/* Header */}
          <div className="text-center mb-8">
            <h1 className="text-4xl font-bold mb-4">Terms of Service</h1>
            <p className="text-lg text-gray-300">
              Effective Date: January 15, 2024 | Last Updated: January 15, 2024
            </p>
          </div>

          {/* Content */}
          <div className="prose prose-lg max-w-none prose-invert">
            <section className="mb-8">
              <h2 className="text-2xl font-semibold mb-4">
                Agreement to Terms
              </h2>
              <p>
                By accessing or using PLOScope (&quot;the Service&quot;), you
                agree to be bound by these Terms of Service (&quot;Terms&quot;).
                If you do not agree to these Terms, you may not use the Service.
              </p>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold mb-4">
                Description of Service
              </h2>
              <p>PLOScope is a poker analysis platform that provides:</p>
              <ul className="list-disc list-inside mb-4">
                <li>Pot Limit Omaha (PLO) equity calculations</li>
                <li>Hand analysis and simulation tools</li>
                <li>Saved poker scenarios (&quot;Spots&quot;)</li>
                <li>Player profile analysis</li>
                <li>Premium features for subscribers</li>
              </ul>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold mb-4">Eligibility</h2>
              <p>To use the Service, you must:</p>
              <ul className="list-disc list-inside mb-4">
                <li>Be at least 18 years old</li>
                <li>Have the legal capacity to enter into agreements</li>
                <li>
                  Not be prohibited from using the Service under applicable laws
                </li>
                <li>
                  Comply with all local laws regarding online poker tools and
                  analysis
                </li>
              </ul>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold mb-4">
                Account Registration
              </h2>

              <h3 className="text-xl font-medium mb-3">Account Creation</h3>
              <ul className="list-disc list-inside mb-4">
                <li>You must provide accurate and complete information</li>
                <li>You are responsible for maintaining account security</li>
                <li>
                  You must promptly update any changes to your information
                </li>
                <li>One person may not maintain multiple accounts</li>
              </ul>

              <h3 className="text-xl font-medium mb-3">Account Security</h3>
              <ul className="list-disc list-inside mb-4">
                <li>You are solely responsible for your account credentials</li>
                <li>
                  You must notify us immediately of any unauthorized access
                </li>
                <li>
                  We are not liable for losses due to unauthorized account use
                </li>
                <li>
                  You agree to use strong passwords and secure authentication
                  methods
                </li>
              </ul>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold mb-4">Acceptable Use</h2>

              <h3 className="text-xl font-medium mb-3">Permitted Uses</h3>
              <ul className="list-disc list-inside mb-4">
                <li>
                  Analyze poker hands and scenarios for educational purposes
                </li>
                <li>Save and organize your poker analysis</li>
                <li>
                  Share analysis with other users through appropriate channels
                </li>
                <li>
                  Use premium features according to your subscription level
                </li>
              </ul>

              <h3 className="text-xl font-medium mb-3">Prohibited Uses</h3>
              <p>You may not:</p>
              <ul className="list-disc list-inside mb-4">
                <li>Use the Service for illegal activities</li>
                <li>Violate any applicable laws or regulations</li>
                <li>Infringe on intellectual property rights</li>
                <li>Transmit harmful or malicious code</li>
                <li>Attempt to gain unauthorized access to our systems</li>
                <li>Use the Service to harass, abuse, or harm others</li>
                <li>Create multiple accounts or share accounts</li>
                <li>Scrape or systematically download content</li>
                <li>Reverse engineer or decompile our software</li>
              </ul>

              <h3 className="text-xl font-medium mb-3">Real Money Gambling</h3>
              <ul className="list-disc list-inside mb-4">
                <li>
                  The Service is for analysis and educational purposes only
                </li>
                <li>We do not facilitate real money gambling</li>
                <li>
                  Users are responsible for complying with local gambling laws
                </li>
                <li>
                  The Service should not be used during live play where
                  prohibited
                </li>
              </ul>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold mb-4">
                Intellectual Property
              </h2>

              <h3 className="text-xl font-medium mb-3">Our Rights</h3>
              <ul className="list-disc list-inside mb-4">
                <li>
                  PLOScope owns all rights to the Service, including software,
                  algorithms, and content
                </li>
                <li>Our trademarks, logos, and branding are protected</li>
                <li>
                  The Service&apos;s source code and proprietary methods are
                  confidential
                </li>
                <li>
                  Users receive a limited license to use the Service, not
                  ownership
                </li>
              </ul>

              <h3 className="text-xl font-medium mb-3">User Content</h3>
              <ul className="list-disc list-inside mb-4">
                <li>
                  You retain ownership of poker scenarios and analysis you
                  create
                </li>
                <li>
                  You grant us a license to store, process, and display your
                  content
                </li>
                <li>
                  You are responsible for ensuring you have rights to any
                  content you upload
                </li>
                <li>We may remove content that violates these Terms</li>
              </ul>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold mb-4">Payment Terms</h2>

              <h3 className="text-xl font-medium mb-3">Subscription Plans</h3>
              <ul className="list-disc list-inside mb-4">
                <li>Premium features require a paid subscription</li>
                <li>Subscription fees are charged in advance</li>
                <li>Prices are subject to change with notice</li>
                <li>All fees are non-refundable except as required by law</li>
              </ul>

              <h3 className="text-xl font-medium mb-3">Payment Processing</h3>
              <ul className="list-disc list-inside mb-4">
                <li>Payments are processed by Stripe</li>
                <li>You must provide valid payment information</li>
                <li>
                  You authorize recurring charges for subscription renewals
                </li>
                <li>Failed payments may result in service suspension</li>
              </ul>

              <h3 className="text-xl font-medium mb-3">
                Refunds and Cancellations
              </h3>
              <ul className="list-disc list-inside mb-4">
                <li>You may cancel your subscription at any time</li>
                <li>
                  Cancellations take effect at the end of the current billing
                  period
                </li>
                <li>
                  Refunds are provided only as required by law or our discretion
                </li>
                <li>
                  Unused portions of subscriptions are generally non-refundable
                </li>
              </ul>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold mb-4">
                Limitation of Liability
              </h2>

              <div className="p-4 rounded-lg mb-4 bg-gray-800 border border-gray-700">
                <h3 className="text-lg font-medium mb-2">
                  Disclaimer of Warranties
                </h3>
                <p className="text-sm">
                  THE SERVICE IS PROVIDED &quot;AS IS&quot; WITHOUT WARRANTIES
                  OF ANY KIND. WE DISCLAIM ALL WARRANTIES, EXPRESS OR IMPLIED,
                  INCLUDING MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE,
                  AND NON-INFRINGEMENT.
                </p>
              </div>

              <div className="p-4 rounded-lg mb-4 bg-gray-800 border border-gray-700">
                <h3 className="text-lg font-medium mb-2">
                  Limitation of Damages
                </h3>
                <p className="text-sm">
                  TO THE MAXIMUM EXTENT PERMITTED BY LAW, WE SHALL NOT BE LIABLE
                  FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR
                  PUNITIVE DAMAGES, INCLUDING LOSS OF PROFITS, DATA, OR USE.
                </p>
              </div>

              <div className="p-4 rounded-lg mb-4 bg-gray-800 border border-gray-700">
                <h3 className="text-lg font-medium mb-2">Maximum Liability</h3>
                <p className="text-sm">
                  OUR TOTAL LIABILITY TO YOU SHALL NOT EXCEED THE AMOUNT YOU
                  PAID FOR THE SERVICE IN THE 12 MONTHS PRECEDING THE CLAIM.
                </p>
              </div>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold mb-4">Termination</h2>

              <h3 className="text-xl font-medium mb-3">
                Your Right to Terminate
              </h3>
              <ul className="list-disc list-inside mb-4">
                <li>You may delete your account at any time</li>
                <li>
                  Account deletion will remove your access to premium features
                </li>
                <li>
                  Some data may be retained for legal or business purposes
                </li>
                <li>
                  Paid subscriptions continue until the end of the billing
                  period
                </li>
              </ul>

              <h3 className="text-xl font-medium mb-3">
                Our Right to Terminate
              </h3>
              <p>We may suspend or terminate your access if you:</p>
              <ul className="list-disc list-inside mb-4">
                <li>Violate these Terms</li>
                <li>Engage in prohibited activities</li>
                <li>Fail to pay subscription fees</li>
                <li>Pose a security risk to the Service</li>
              </ul>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold mb-4">Changes to Terms</h2>
              <ul className="list-disc list-inside mb-4">
                <li>We may update these Terms from time to time</li>
                <li>
                  Material changes will be communicated through the Service or
                  email
                </li>
                <li>
                  Your continued use constitutes acceptance of updated Terms
                </li>
                <li>
                  If you don&apos;t agree to changes, you must stop using the
                  Service
                </li>
              </ul>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold mb-4">
                Contact Information
              </h2>
              <p>For questions about these Terms, contact us at:</p>
              <ul className="list-disc list-inside mb-4">
                <li>
                  <strong>Email:</strong> legal@ploscope.com
                </li>
                <li>
                  <strong>Website:</strong> https://ploscope.com/terms
                </li>
              </ul>
            </section>

            <div className="p-6 rounded-lg text-center bg-blue-900 border border-blue-700">
              <p className="font-medium">
                <strong>
                  By using PLOScope, you acknowledge that you have read,
                  understood, and agree to be bound by these Terms of Service.
                </strong>
              </p>
              <p className="text-sm mt-2">Last updated: January 15, 2024</p>
            </div>
          </div>

          {/* Back to Top Button */}
          <div className="text-center mt-8">
            <button
              onClick={() => window.scrollTo({ top: 0, behavior: 'smooth' })}
              className="px-6 py-3 rounded-lg font-medium transition-colors bg-blue-600 hover:bg-blue-700 text-white"
            >
              Back to Top
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default TermsOfService;
