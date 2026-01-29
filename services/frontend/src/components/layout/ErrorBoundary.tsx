import React, { Component } from 'react';

import { trackError } from '../../utils/analytics';

type ErrorBoundaryState = {
  hasError: boolean;
  error: Error | null;
  errorInfo: { componentStack: string } | null;
  eventId: string | null;
};

class ErrorBoundary extends Component<
  React.PropsWithChildren<Record<string, never>>,
  ErrorBoundaryState
> {
  constructor(props: React.PropsWithChildren<Record<string, never>>) {
    super(props);
    this.state = {
      hasError: false,
      error: null,
      errorInfo: null,
      eventId: null,
    };
  }

  static getDerivedStateFromError(): Partial<ErrorBoundaryState> {
    // Update state so the next render will show the fallback UI
    return { hasError: true };
  }

  componentDidCatch(error: Error, errorInfo: { componentStack: string }) {
    // Log error details

    // Generate unique error ID
    const eventId =
      Date.now().toString(36) + Math.random().toString(36).substr(2);

    // Report to analytics/telemetry service
    trackError('error_boundary', error?.message || 'Unknown error', {
      context: 'ErrorBoundary',
      errorInfo: errorInfo?.componentStack,
      eventId,
      url: window.location.href,
      userAgent: navigator.userAgent,
    });

    this.setState({
      error,
      errorInfo,
      eventId,
    });
  }

  handleRetry() {
    this.setState({
      hasError: false,
      error: null,
      errorInfo: null,
      eventId: null,
    });
  }

  handleReportBug() {
    const { error, errorInfo, eventId } = this.state;
    const errorReport = {
      message: error?.message || 'Unknown error',
      stack: error?.stack || 'No stack trace',
      componentStack: errorInfo?.componentStack || 'No component stack',
      eventId,
      url: window.location.href,
      timestamp: new Date().toISOString(),
      userAgent: navigator.userAgent,
    };

    // Create email with error details
    const subject = `Bug Report - PLOScope Error ${eventId}`;
    const body = `
Please describe what you were doing when this error occurred:

[Your description here]

Error Details:
${JSON.stringify(errorReport, null, 2)}
    `.trim();

    const mailtoLink = `mailto:support@ploscope.com?subject=${encodeURIComponent(subject)}&body=${encodeURIComponent(body)}`;
    window.open(mailtoLink);
  }

  render() {
    if (this.state.hasError) {
      return (
        <ErrorFallbackUI
          error={this.state.error}
          eventId={this.state.eventId}
          onRetry={this.handleRetry.bind(this)}
          onReportBug={this.handleReportBug.bind(this)}
        />
      );
    }

    return this.props.children as React.ReactElement;
  }
}

type ErrorFallbackProps = {
  error: Error | null;
  eventId: string | null;
  onRetry: () => void;
  onReportBug: () => void;
};

const ErrorFallbackUI: React.FC<ErrorFallbackProps> = ({
  error,
  eventId,
  onRetry,
  onReportBug,
}) => {
  return (
    <div className="min-h-screen flex items-center justify-center p-4 bg-gray-900 text-white">
      <div className="max-w-md w-full p-6 rounded-lg border bg-gray-800 border-gray-700">
        <div className="text-center mb-6">
          <div className="text-4xl mb-4">💥</div>
          <h1 className="text-2xl font-bold mb-2">
            Oops! Something went wrong
          </h1>
          <p className="text-sm text-gray-300">
            We&apos;re sorry, but an unexpected error occurred. Our team has
            been notified.
          </p>
        </div>

        <div className="p-4 rounded-lg mb-6 bg-gray-700">
          <div className="text-xs font-mono">
            <div className="mb-2">
              <strong>Error ID:</strong> {eventId}
            </div>
            <div className="mb-2">
              <strong>Message:</strong> {error?.message || 'Unknown error'}
            </div>
            <div>
              <strong>Time:</strong> {new Date().toLocaleString()}
            </div>
          </div>
        </div>

        <div className="space-y-3">
          <button
            onClick={onRetry}
            className="w-full py-3 px-4 rounded-lg font-medium transition-colors bg-blue-600 hover:bg-blue-700 text-white"
          >
            Try Again
          </button>

          <button
            onClick={() => (window.location.href = '/')}
            className="w-full py-3 px-4 rounded-lg font-medium transition-colors bg-gray-600 hover:bg-gray-700 text-white"
          >
            Go to Home
          </button>

          <button
            onClick={onReportBug}
            className="w-full py-2 px-4 rounded-lg font-medium transition-colors border border-gray-600 hover:bg-gray-700 text-gray-300"
          >
            Report Bug
          </button>
        </div>

        <div className="mt-6 pt-4 border-t text-center text-xs border-gray-700 text-gray-400">
          If this problem persists, please contact{' '}
          <a href="mailto:support@ploscope.com" className="text-blue-400">
            support@ploscope.com
          </a>
        </div>
      </div>
    </div>
  );
};

export default ErrorBoundary;
