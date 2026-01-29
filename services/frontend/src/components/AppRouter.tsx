import React, { Suspense, lazy, useState } from 'react';

import {
  BrowserRouter as Router,
  Routes,
  Route,
  Navigate,
} from 'react-router-dom';

import { AppWrapper, ProtectedRoute, AppFooter, AppHeader } from './layout';
import { CookieConsent, LoadingSpinner } from './ui';

const LandingPage = lazy(() => import('@/pages/landingPage/LandingPage'));
const PricingPage = lazy(() => import('@/pages/pricing/PricingPage'));
const BlogList = lazy(() => import('../pages/blog/BlogList'));
const BlogPost = lazy(() => import('../pages/blog/BlogPost'));
const Checkout = lazy(() => import('@/pages/checkoutPage/Checkout'));
const CheckoutSuccess = lazy(
  () => import('@/pages/checkoutPage/CheckoutSuccess')
);
const PrivacyPolicy = lazy(() => import('@/pages/privacyPolicy/PrivacyPolicy'));
const TermsOfService = lazy(() => import('@/pages/tos/TermsOfService'));
const CookieSettings = lazy(
  () => import('@/pages/checkoutPage/CookieSettings')
);
const ProfilePage = lazy(() => import('@/pages/profilePage/ProfilePage'));
const FAQPage = lazy(() => import('@/pages/FAQ/FAQPage'));
const SupportPage = lazy(() => import('@/pages/supportPage/SupportPage'));
const LiveModePage = lazy(() => import('@/pages/liveMode/LiveModePage'));
const JobsPage = lazy(() => import('@/pages/jobsPage/JobsPage'));
const AccessDeniedPage = lazy(() => import('@/pages/accessDenied/AccessDeniedPage'));

const AppLoadingSpinner: React.FC = () => (
  <div className="app-loading-container">
    <LoadingSpinner text="Loading..." />
  </div>
);

const AppRouter: React.FC = () => {
  return (
    <Router>
      <AppHeader />
      <Suspense fallback={<AppLoadingSpinner />}>
        <Routes>
          <Route path="/" element={<LandingPage />} />
          <Route path="/pricing" element={<PricingPage />} />
          <Route path="/blog" element={<BlogList />} />
          <Route path="/blog/:slug" element={<BlogPost />} />
          <Route path="/privacy" element={<PrivacyPolicy />} />
          <Route path="/terms" element={<TermsOfService />} />
          <Route path="/cookies" element={<CookieSettings />} />
          <Route path="/faq" element={<FAQPage />} />
          <Route path="/support" element={<SupportPage />} />
          <Route path="/checkout" element={<Checkout />} />
          <Route path="/checkout/success" element={<CheckoutSuccess />} />
          <Route path="/access-denied" element={<AccessDeniedPage />} />
          <Route
            path="/profile"
            element={
              <ProtectedRoute>
                <ProfilePage />
              </ProtectedRoute>
            }
          />
          <Route
            path="/app"
            element={
              <ProtectedRoute>
                <AppWrapper />
              </ProtectedRoute>
            }
          >
            <Route index element={<Navigate to="/app/live" replace />} />
            <Route path="live" element={<LiveModePage />} />
            <Route path="jobs" element={<JobsPage />} />
          </Route>
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </Suspense>
      <CookieConsent />
      <AppFooter />
    </Router>
  );
};

export default AppRouter;
