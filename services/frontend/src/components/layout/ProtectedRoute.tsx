import React from 'react';

import { Navigate } from 'react-router-dom';

import { useAuth } from '../../contexts/AuthContext';
import { LoadingSpinner } from '../ui';

const ProtectedRoute: React.FC<{ children: React.ReactElement }> = ({
  children,
}) => {
  const { isAuthenticated, loading } = useAuth();

  // Show loading spinner while checking authentication
  if (loading) {
    return (
      <div className="loading-container">
        <LoadingSpinner text="Loading..." />
      </div>
    );
  }

  // Redirect to access denied page if not authenticated
  if (!isAuthenticated) {
    return <Navigate to="/access-denied" replace />;
  }

  // Render the protected component if authenticated
  return children;
};

export default ProtectedRoute;
