import React from 'react';

import JobStatusPanel from '@/components/jobs/JobStatusPanel';
import './JobsPage.scss';

const JobsPage: React.FC = () => {
  return (
    <div className="jobs-page-container">
      <main className="jobs-page-content">
        <JobStatusPanel />
      </main>
    </div>
  );
};

export default JobsPage;
