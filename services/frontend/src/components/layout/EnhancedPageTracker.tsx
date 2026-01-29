import { useEffect } from 'react';

import { useEnhancedPageTracking } from '../../hooks/useAnalytics';

type EnhancedPageTrackerProps = {
  path: string;
  title: string;
  params?: Record<string, unknown>;
  deps?: unknown[];
};

const EnhancedPageTracker = ({ path, title, params = {}, deps = [] }: EnhancedPageTrackerProps) => {
  useEnhancedPageTracking(path, title, params, deps);

  // Render nothing; this component is side-effect-only
  return null;
};

export default EnhancedPageTracker;


