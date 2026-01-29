import React from 'react';

const PrivacyPolicy = () => {
  return (
    <div className="min-h-screen bg-gray-900 text-white">
      <div className="container mx-auto px-4 py-8">
        <div className="max-w-4xl mx-auto">
          {/* Header */}
          <div className="text-center mb-8">
            <h1 className="text-4xl font-bold mb-4">Privacy Policy</h1>
            <p className="text-lg text-gray-300">
              Effective Date: January 15, 2024 | Last Updated: January 15, 2024
            </p>
          </div>

          {/* Content */}
          <div className="prose prose-lg max-w-none prose-invert">
            <section className="mb-8">
              <h2 className="text-2xl font-semibold mb-4">Introduction</h2>
              <p>
                PLOScope (&quot;we,&quot; &quot;our,&quot; or &quot;us&quot;) is
                committed to protecting your privacy. This Privacy Policy
                explains how we collect, use, disclose, and safeguard your
                information when you use our poker analysis service and website.
              </p>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold mb-4">
                Information We Collect
              </h2>

              <h3 className="text-xl font-medium mb-3">Personal Information</h3>
              <p>We may collect the following personal information:</p>
              <ul className="list-disc list-inside mb-4">
                <li>
                  <strong>Account Information:</strong> Email address, username,
                  first and last name
                </li>
                <li>
                  <strong>Authentication Data:</strong> Encrypted passwords,
                </li>
                <li>
                  <strong>Profile Information:</strong> Profile pictures, user
                  preferences
                </li>
                <li>
                  <strong>Subscription Information:</strong> Payment details,
                  subscription tier, billing history
                </li>
              </ul>

              <h3 className="text-xl font-medium mb-3">
                Technical Information
              </h3>
              <p>We automatically collect certain technical information:</p>
              <ul className="list-disc list-inside mb-4">
                <li>
                  <strong>Usage Data:</strong> Pages visited, features used,
                  time spent on service
                </li>
                <li>
                  <strong>Device Information:</strong> Browser type, operating
                  system, device identifiers
                </li>
                <li>
                  <strong>Network Information:</strong> IP address, connection
                  type, location data
                </li>
                <li>
                  <strong>Log Data:</strong> Server logs, error reports,
                  performance metrics
                </li>
              </ul>

              <h3 className="text-xl font-medium mb-3">Game Data</h3>
              <ul className="list-disc list-inside mb-4">
                <li>
                  <strong>Poker Hands:</strong> Cards, board states, player
                  configurations you analyze
                </li>
                <li>
                  <strong>Saved Spots:</strong> Your saved poker scenarios and
                  analysis results
                </li>
                <li>
                  <strong>Simulation Settings:</strong> Your preferred analysis
                  parameters
                </li>
              </ul>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold mb-4">
                How We Use Your Information
              </h2>

              <h3 className="text-xl font-medium mb-3">Service Provision</h3>
              <ul className="list-disc list-inside mb-4">
                <li>Provide and maintain our poker analysis tools</li>
                <li>Process your account registration and authentication</li>
                <li>Enable premium features for subscribed users</li>
                <li>Sync your data across devices</li>
              </ul>

              <h3 className="text-xl font-medium mb-3">Communication</h3>
              <ul className="list-disc list-inside mb-4">
                <li>Send service-related notifications</li>
                <li>Provide customer support</li>
                <li>Send updates about new features or changes</li>
                <li>Marketing communications (with your consent)</li>
              </ul>

              <h3 className="text-xl font-medium mb-3">
                Analytics and Improvement
              </h3>
              <ul className="list-disc list-inside mb-4">
                <li>Analyze usage patterns to improve our service</li>
                <li>Debug technical issues and optimize performance</li>
                <li>Develop new features based on user behavior</li>
                <li>Conduct research on poker strategy and gameplay</li>
              </ul>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold mb-4">
                Information Sharing
              </h2>
              <p className="mb-4">
                <strong>We do not sell your personal information.</strong> We
                may share your information in the following circumstances:
              </p>

              <h3 className="text-xl font-medium mb-3">Service Providers</h3>
              <p>
                We may share information with trusted third-party service
                providers who assist us in:
              </p>
              <ul className="list-disc list-inside mb-4">
                <li>Payment processing (Stripe)</li>
                <li>Cloud hosting and storage</li>
                <li>Analytics and monitoring</li>
                <li>Customer support tools</li>
              </ul>

              <h3 className="text-xl font-medium mb-3">Legal Requirements</h3>
              <p>We may disclose information when required by law or to:</p>
              <ul className="list-disc list-inside mb-4">
                <li>Comply with legal process or government requests</li>
                <li>Protect our rights, property, or safety</li>
                <li>Protect the rights, property, or safety of our users</li>
                <li>Investigate fraud or security issues</li>
              </ul>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold mb-4">Data Security</h2>
              <p>
                We implement appropriate security measures to protect your
                information:
              </p>

              <h3 className="text-xl font-medium mb-3">Technical Safeguards</h3>
              <ul className="list-disc list-inside mb-4">
                <li>Encryption of sensitive data in transit and at rest</li>
                <li>Secure authentication and session management</li>
                <li>Regular security assessments and updates</li>
                <li>Access controls and monitoring</li>
              </ul>

              <h3 className="text-xl font-medium mb-3">
                Organizational Safeguards
              </h3>
              <ul className="list-disc list-inside mb-4">
                <li>
                  Limited access to personal information on a need-to-know basis
                </li>
                <li>Employee training on privacy and security practices</li>
                <li>Incident response procedures</li>
                <li>Regular security policy reviews</li>
              </ul>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold mb-4">
                Your Rights and Choices
              </h2>
              <p>
                Depending on your location, you may have the following rights:
              </p>

              <h3 className="text-xl font-medium mb-3">Access and Control</h3>
              <ul className="list-disc list-inside mb-4">
                <li>
                  <strong>Access:</strong> Request a copy of your personal
                  information
                </li>
                <li>
                  <strong>Correction:</strong> Update or correct inaccurate
                  information
                </li>
                <li>
                  <strong>Deletion:</strong> Request deletion of your personal
                  information
                </li>
                <li>
                  <strong>Portability:</strong> Request your data in a portable
                  format
                </li>
              </ul>

              <h3 className="text-xl font-medium mb-3">Account Management</h3>
              <ul className="list-disc list-inside mb-4">
                <li>
                  <strong>Account Deletion:</strong> Delete your account and
                  associated data
                </li>
                <li>
                  <strong>Data Export:</strong> Download your saved poker
                  scenarios and analysis
                </li>
                <li>
                  <strong>Subscription Management:</strong> Cancel or modify
                  your subscription
                </li>
              </ul>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold mb-4">
                Contact Information
              </h2>
              <p>
                If you have questions about this Privacy Policy or our privacy
                practices, please contact us:
              </p>
              <ul className="list-disc list-inside mb-4">
                <li>
                  <strong>Email:</strong> privacy@ploscope.com
                </li>
                <li>
                  <strong>Website:</strong> https://ploscope.com/privacy
                </li>
              </ul>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold mb-4">
                Regional Privacy Rights
              </h2>

              <h3 className="text-xl font-medium mb-3">
                California Residents (CCPA)
              </h3>
              <p>
                California residents have additional rights under the California
                Consumer Privacy Act:
              </p>
              <ul className="list-disc list-inside mb-4">
                <li>Right to know what personal information is collected</li>
                <li>Right to delete personal information</li>
                <li>Right to opt-out of the sale of personal information</li>
                <li>
                  Right to non-discrimination for exercising privacy rights
                </li>
              </ul>

              <h3 className="text-xl font-medium mb-3">
                European Residents (GDPR)
              </h3>
              <p>
                European residents have additional rights under the General Data
                Protection Regulation:
              </p>
              <ul className="list-disc list-inside mb-4">
                <li>Right to access and rectification</li>
                <li>Right to erasure and restriction of processing</li>
                <li>Right to data portability</li>
                <li>Right to object to processing</li>
                <li>Right to withdraw consent</li>
              </ul>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold mb-4">
                Changes to This Privacy Policy
              </h2>
              <p>
                We may update this Privacy Policy from time to time. We will
                notify you of material changes by:
              </p>
              <ul className="list-disc list-inside mb-4">
                <li>Posting the updated policy on our website</li>
                <li>Sending an email notification (for significant changes)</li>
                <li>Providing in-app notifications</li>
              </ul>
              <p>
                Your continued use of our service after changes take effect
                constitutes acceptance of the updated policy.
              </p>
            </section>
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

export default PrivacyPolicy;
