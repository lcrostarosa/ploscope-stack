import React, { createContext, useContext, useState, useEffect } from 'react';

import { api } from '../utils/auth';
import { logError } from '../utils/logger';

import { useAuth } from './AuthContext';

interface JobContextValue {
  activeJobCount: number;
  refreshJobCount: () => void;
}

const JobContext = createContext<JobContextValue | null>(null);

export const useJobContext = (): JobContextValue => {
  const context = useContext(JobContext);
  if (!context) {
    throw new Error('useJobContext must be used within a JobProvider');
  }
  return context;
};

export const JobProvider: React.FC<{ children: React.ReactNode }> = ({
  children,
}) => {
  const { user } = useAuth();
  const [activeJobCount, setActiveJobCount] = useState(0);

  const fetchJobCount = async () => {
    if (!user) {
      setActiveJobCount(0);
      return;
    }

    try {
      const res = await api.get('/jobs/recent');
      const count = (res.data?.active_jobs || []).length;
      setActiveJobCount(count);
    } catch (err) {
      logError('Job count fetch failed', err);
    }
  };

  const refreshJobCount = () => {
    fetchJobCount();
  };

  // Reset job count when user logs out
  useEffect(() => {
    if (!user) {
      setActiveJobCount(0);
    }
  }, [user]);

  const value = {
    activeJobCount,
    refreshJobCount,
  };

  return <JobContext.Provider value={value}>{children}</JobContext.Provider>;
};

export default JobContext;
