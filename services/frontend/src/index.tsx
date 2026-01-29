import React from 'react';

import { createRoot } from 'react-dom/client';

import AppRouter from './components/AppRouter';
import { ToastProvider } from './components/ui';
import { AuthProvider } from './contexts/AuthContext';
import { JobProvider } from './contexts/JobContext';
import { trackEvent } from './utils/analytics';
import { initializeAnalyticsIfAllowed } from './utils/cookieConsent';

import '@/components/forms/Forms.scss';
import '@/styles/Main.scss';
import './components/ui/Buttons.scss';
import './components/ui/Modal.scss';

initializeAnalyticsIfAllowed();

const App: React.FC = () => {
  return <AppRouter />;
};

const container = document.getElementById('root');
if (!container) {
  throw new Error('Root container missing');
}
const root = createRoot(container);

document.addEventListener('click', (e: MouseEvent) => {
  const target = e.target as HTMLElement | null;
  const el = target?.closest('[data-analytics-id]') as HTMLElement | null;
  if (!el) return;
  const id = el.getAttribute('data-analytics-id') || undefined;
  const label =
    el.getAttribute('data-analytics-label') ||
    (el.textContent || '').trim().slice(0, 80);
  trackEvent('button_click', {
    category: 'interaction',
    analytics_id: id ?? 'unknown',
    label,
    page_path: window.location.pathname,
  });
});

root.render(
  <AuthProvider>
    <JobProvider>
      <ToastProvider>
        <App />
      </ToastProvider>
    </JobProvider>
  </AuthProvider>
);
