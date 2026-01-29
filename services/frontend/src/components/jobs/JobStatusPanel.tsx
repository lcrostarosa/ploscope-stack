import React, { useState, useEffect, useRef, useCallback } from 'react';

import { useNavigate } from 'react-router-dom';

import type { JobStatusPanelProps } from '@/types/ComponentTypes';
import type { Job, CreditsInfo, JobUpdatePayload } from '@/types/Job';

import { useJobContext } from '../../contexts/JobContext';
import type { SpotModeData } from '../../types/SpotModeData';
import { api } from '../../utils/auth';
import { convertCardsForFrontend } from '../../utils/constants';
import { scrollToElementById } from '../../utils/domUtils';
import { logError, logDebug, logInfo } from '../../utils/logger';
import { useToast } from '../ui';
import './JobStatusPanel.scss';

const JobStatusPanel: React.FC<JobStatusPanelProps> = ({
  onJobCompleted,
  onLoadSpotData,
  isActive = true, // Default to true for backward compatibility
}) => {
  const navigate = useNavigate();
  const toast = useToast();
  const { refreshJobCount } = useJobContext();
  const [jobs, setJobs] = useState<Job[]>([]);
  const [credits, setCredits] = useState<CreditsInfo | null>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [loadingResultsId, setLoadingResultsId] = useState<string | number | null>(null);
  const [currentPage, setCurrentPage] = useState<number>(1);
  const [pageSize, setPageSize] = useState<number>(10);
  const [error, setError] = useState<string | null>(null);
  const retryCountRef = useRef(0);

  const completedJobIdsRef = useRef<Set<string | number>>(new Set());

  const isFirstFetchRef = useRef(true);

  const isFetchingRef = useRef<boolean>(false);
  const abortControllerRef = useRef<AbortController | null>(null);
  const [isCollapsed, setIsCollapsed] = useState(false);
  const onJobCompletedRef =
    useRef<JobStatusPanelProps['onJobCompleted']>(onJobCompleted);



  useEffect(() => {
    onJobCompletedRef.current = onJobCompleted;
  }, [onJobCompleted]);


  const fetchRecentJobs = useCallback(async () => {
    try {
      if (isFetchingRef.current) return;
      isFetchingRef.current = true;
      // Abort any in-flight request before starting a new one
      if (abortControllerRef.current) {
        try {
          abortControllerRef.current.abort();
        } catch {
          /* noop */
        }
      }
      abortControllerRef.current = new AbortController();

      const response = await api.get('/jobs/recent', {
        signal: abortControllerRef.current.signal,
      });
      logDebug('JobStatusPanel: Raw API response:', response.data);

      // Combine active jobs and recent jobs, prioritizing active jobs
      const activeJobs = response.data.active_jobs || [];
      const recentJobs = response.data.recent_jobs || [];

      logDebug('JobStatusPanel: Active jobs:', activeJobs);
      logDebug('JobStatusPanel: Recent jobs:', recentJobs);

      // Merge jobs, avoiding duplicates (active jobs take priority)
      const allJobs: Job[] = [...activeJobs];
      recentJobs.forEach((job: Job) => {
        if (!activeJobs.find((activeJob: Job) => activeJob.id === job.id)) {
          allJobs.push(job);
        }
      });

      logDebug('JobStatusPanel: All jobs after merge:', allJobs);

      // Prepare active and completed job lists
      const activeJobsFiltered = allJobs.filter(
        (job: Job) =>
          job.status === 'queued' ||
          job.status === 'QUEUED' ||
          job.status === 'processing' ||
          job.status === 'PROCESSING'
      );
      const completedJobsFiltered = allJobs.filter(
        (job: Job) =>
          job.status === 'completed' ||
          job.status === 'COMPLETED' ||
          job.status === 'failed' ||
          job.status === 'FAILED' ||
          job.status === 'cancelled' ||
          job.status === 'CANCELLED'
      );

      logInfo('JobStatusPanel: Job filtering results', {
        totalJobs: allJobs.length,
        activeJobsCount: activeJobsFiltered.length,
        completedJobsCount: completedJobsFiltered.length,
        activeJobIds: activeJobsFiltered.map(j => j.id),
        completedJobIds: completedJobsFiltered.map(j => j.id),
      });

      logDebug('JobStatusPanel: Active jobs filtered:', activeJobsFiltered);
      logDebug(
        'JobStatusPanel: Completed jobs filtered:',
        completedJobsFiltered
      );

      // Sort both groups by created_at (desc)
      const parseTs = (d?: string) => (d ? new Date(d).getTime() : 0);
      activeJobsFiltered.sort((a: Job, b: Job) => parseTs(b.created_at) - parseTs(a.created_at));
      completedJobsFiltered.sort((a: Job, b: Job) => parseTs(b.created_at) - parseTs(a.created_at));

      // Show all jobs: active first, then completed/failed/cancelled
      const orderedJobs: Job[] = [...activeJobsFiltered, ...completedJobsFiltered];

      logInfo('JobStatusPanel: Final job ordering', {
        totalJobs: orderedJobs.length,
        activeJobsCount: activeJobsFiltered.length,
        completedJobsCount: completedJobsFiltered.length,
        finalJobIds: orderedJobs.map(j => j.id),
      });

      logDebug('JobStatusPanel: Final ordered jobs:', orderedJobs);

      setJobs(orderedJobs);
      // Reset to first page on refresh so new jobs are visible
      setCurrentPage(1);
      logDebug('JobStatusPanel: Jobs set in state:', orderedJobs);
      setCredits(response.data.credits_info);
      setError(null);
      retryCountRef.current = 0; // Reset retry count on success
      
      // Update job count in context for header badge
      refreshJobCount();

      // Check for newly completed jobs and call the callback (only for polling)
      logInfo('JobStatusPanel: Checking for completed jobs in polling', {
        hasCallback: !!onJobCompletedRef.current,
        isFirstFetch: isFirstFetchRef.current,
        isActive: isActive,
        allJobsCount: allJobs.length,
        completedJobIds: Array.from(completedJobIdsRef.current),
        allJobStatuses: allJobs.map(j => ({ id: j.id, status: j.status })),
      });

      if (onJobCompletedRef.current && !isFirstFetchRef.current) {
        allJobs.forEach((job: Job) => {
          logInfo('JobStatusPanel: Checking job in polling', {
            jobId: job.id,
            status: job.status,
            isCompleted: job.status === 'completed' || job.status === 'COMPLETED',
            alreadyProcessed: completedJobIdsRef.current.has(job.id),
          });
          
          // Call callback for completed, failed, or cancelled jobs that haven't been processed yet
          if (
            (job.status === 'completed' ||
              job.status === 'COMPLETED' ||
              job.status === 'failed' ||
              job.status === 'FAILED' ||
              job.status === 'cancelled' ||
              job.status === 'CANCELLED') &&
            !completedJobIdsRef.current.has(job.id)
          ) {
            completedJobIdsRef.current.add(job.id);
            logInfo('JobStatusPanel: Triggering onJobCompleted callback for job:', {
              jobId: job.id,
              status: job.status,
              hasResults: !!job.results,
              isFirstFetch: isFirstFetchRef.current,
              source: 'Polling',
            });
            // Defer the callback to avoid setState during render
            // For completed jobs, fetch full details to get results
            setTimeout(async () => {
              if (onJobCompletedRef.current) {
                if (job.status === 'completed' || job.status === 'COMPLETED') {
                  try {
                    // Fetch full job details to get results
                    const response = await api.get(`/jobs/${job.id}/details`);
                    const fullJob = response.data.job;
                    logInfo('JobStatusPanel: Fetched full job details for callback:', {
                      jobId: fullJob.id,
                      hasResults: !!fullJob.result_data,
                      resultDataType: typeof fullJob.result_data,
                    });
                    onJobCompletedRef.current(fullJob);
                  } catch (error) {
                    logError('JobStatusPanel: Failed to fetch full job details:', error);
                    // Fallback to original job object
                    onJobCompletedRef.current(job);
                  }
                } else {
                  // For failed/cancelled jobs, use the original job object
                  onJobCompletedRef.current(job);
                }
              }
            }, 0);
          }
        });
      }

      // Mark first fetch completed so future polls can trigger notifications
      if (isFirstFetchRef.current) {
        isFirstFetchRef.current = false;
      }
    } catch (err: unknown) {
      logError('Failed to fetch job status:', err);

      // Provide more detailed error information
      let errorMessage = 'Failed to load job status';

      if (err && typeof err === 'object' && 'response' in err) {
        const axiosError = err as {
          response: { status: number; data: unknown };
        };
        // Server responded with error status
        const status = axiosError.response.status;
        const data = axiosError.response.data;

        switch (status) {
          case 401:
            errorMessage = 'Authentication failed. Please log in again.';
            break;
          case 403:
            errorMessage = 'Access denied. Please check your permissions.';
            break;
          case 404:
            errorMessage =
              'Job status endpoint not found. Please check server configuration.';
            break;
          case 500:
            errorMessage = 'Server error. Please try again later.';
            break;
          default:
            errorMessage = `Server error (${status}): ${(data as { error?: string })?.error || 'Unknown error'}`;
        }
      } else if (err && typeof err === 'object' && 'request' in err) {
        // Request was made but no response received
        errorMessage =
          'Unable to connect to server. Please check your connection.';
      } else if (err && typeof err === 'object' && 'message' in err) {
        // Something else happened
        errorMessage = `Request error: ${(err as { message: string }).message}`;
      }

      setError(errorMessage);
      // Track a retry without triggering rerenders
      if (retryCountRef.current === 0) {
        retryCountRef.current = 1;
      }
    } finally {
      isFetchingRef.current = false;
      setLoading(false);
    }
  }, []);

  // Only fetch jobs when isActive is true
  useEffect(() => {
    if (!isActive) {
      // Clean up when becoming inactive
      if (abortControllerRef.current) {
        try {
          abortControllerRef.current.abort();
        } catch {
          /* noop */
        }
      }
      isFetchingRef.current = false;
      return;
    }

    fetchRecentJobs();
    const interval = setInterval(fetchRecentJobs, 5000);
    return () => {
      clearInterval(interval);
      if (abortControllerRef.current) {
        try {
          abortControllerRef.current.abort();
        } catch {
          /* noop */
        }
      }
      isFetchingRef.current = false;
    };
  }, [fetchRecentJobs, isActive]);



  const formatDuration = (seconds?: number) => {
    if (!seconds) return 'Unknown';
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return mins > 0 ? `${mins}m ${secs}s` : `${secs}s`;
  };

  const formatActualTimestamp = (dateString?: string) => {
    if (!dateString) return 'Unknown';
    const date = new Date(dateString);
    const now = new Date();
    const diffMs = now.getTime() - date.getTime();
    const diffMins = Math.floor(diffMs / (1000 * 60));
    const diffHours = Math.floor(diffMs / (1000 * 60 * 60));
    const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24));

    if (diffMins < 1) {
      return 'Just now';
    } else if (diffMins < 60) {
      return `${diffMins}m ago`;
    } else if (diffHours < 24) {
      return `${diffHours}h ago`;
    } else if (diffDays < 7) {
      return `${diffDays}d ago`;
    } else {
      return date.toLocaleDateString();
    }
  };

  const getJobTypeDisplay = (jobType: string) => {
    const typeMap = {
      spot_simulation: '🎯',
      solver_simulation: '🧠',
      solver_analysis: '📊',
      equity_calculation: '📊',
    };
    return (typeMap as Record<string, string>)[jobType] || '⚙️';
  };

  const getStatusColor = (status: string) => {
    const colorMap = {
      queued: '#ffa500',
      QUEUED: '#ffa500',
      processing: '#007bff',
      PROCESSING: '#007bff',
      completed: '#28a745',
      COMPLETED: '#28a745',
      failed: '#dc3545',
      FAILED: '#dc3545',
      cancelled: '#6c757d',
      CANCELLED: '#6c757d',
    };
    return (colorMap as Record<string, string>)[status] || '#6c757d';
  };

  const getStatusIcon = (status: string) => {
    const iconMap = {
      queued: '⏳',
      QUEUED: '⏳',
      processing: '🔄',
      PROCESSING: '🔄',
      completed: '✅',
      COMPLETED: '✅',
      failed: '❌',
      FAILED: '❌',
      cancelled: '🚫',
      CANCELLED: '🚫',
    };
    return (iconMap as Record<string, string>)[status] || '❓';
  };

  const getProgressDisplay = (job: Job) => {
    if (job.status === 'queued' || job.status === 'QUEUED') {
      return {
        percentage: 0,
        message: 'Waiting in queue...',
        showPulse: false,
      };
    } else if (job.status === 'processing' || job.status === 'PROCESSING') {
      const percentage = job.progress_percentage || 0;
      const message = job.progress_message || 'Processing...';
      return { percentage, message, showPulse: true };
    } else if (job.status === 'completed' || job.status === 'COMPLETED') {
      return {
        percentage: 100,
        message: 'Completed successfully',
        showPulse: false,
      };
    } else if (job.status === 'failed' || job.status === 'FAILED') {
      return { percentage: 100, message: 'Failed', showPulse: false };
    } else if (job.status === 'cancelled' || job.status === 'CANCELLED') {
      return { percentage: 100, message: 'Cancelled', showPulse: false };
    }
    return { percentage: 0, message: 'Unknown status', showPulse: false };
  };

  const scrollToResults = () => scrollToElementById('simulation-results');

  const cancelJob = async (jobId: string | number) => {
    try {
      await api.post(`/jobs/${jobId}/cancel`);
      // Refresh jobs to get updated status
      fetchRecentJobs();
    } catch (error) {
      logError('Failed to cancel job:', error);
    }
  };

  const loadSpotFromJob = async (job: Job) => {
    try {
      // Fetch full job details to get input_data and result_data
      const response = await api.get(`/jobs/${job.id}/details`);
      const fullJob = response.data.job;

      if (
        fullJob.input_data &&
        typeof fullJob.job_type === 'string' &&
        fullJob.job_type.toLowerCase().includes('spot')
      ) {
        const spotModeData = convertJobDataToSpotMode(fullJob.input_data);

        if (
          fullJob.result_data &&
          (job.status === 'completed' || job.status === 'COMPLETED')
        ) {
          const results = fullJob.result_data?.results || fullJob.result_data;
          spotModeData.spotResults = results;
        }

        // Use the callback to pass data to the parent
        if (onLoadSpotData) {
          onLoadSpotData(spotModeData);
        } else {
          // Fallback to navigate if no callback is provided
          const results =
            fullJob.result_data?.results || fullJob.result_data || undefined;
          navigate('/app/live', {
            state: {
              jobResults: results,
              // Optionally include configuration for future use
              gameState: spotModeData,
              ts: Date.now(),
            },
          });
        }
      } else {
        logError('Invalid job data - missing input_data or wrong job_type');
      }
    } catch (error) {
      logError('Failed to load spot from job:', error);
    }
  };

  const viewSpotResults = async (job: Job) => {
    try {
      setLoadingResultsId(job.id);
      const response = await api.get(`/jobs/${job.id}/details`);
      const fullJob = response.data.job;

      const results = fullJob?.result_data?.results || fullJob?.result_data;
      if (!results) {
        toast.warning('No results available for this job yet.');
        return;
      }

      navigate('/app/live', {
        state: {
          jobResults: results,
          ts: Date.now(),
        },
      });
    } catch (error) {
      logError('Failed to view spot results from job:', error);
      toast.error('Failed to load results for this job.');
    } finally {
      setLoadingResultsId(null);
    }
  };

  // Helper function to convert job input_data to SpotMode format
  const convertJobDataToSpotMode = (
    jobInputData: Record<string, unknown>
  ): SpotModeData => {
    // Handle different job data formats
    if (jobInputData.heroCards && jobInputData.opponentCards) {
      // Already in SpotMode format
      return jobInputData as SpotModeData;
    }

    // Convert from job format to SpotMode format
    const spotModeData = {
      heroCards: ['', '', '', ''] as string[],
      opponentCards: [['', '', '', '']] as string[][],
      communityCards: {
        topFlop: ['', '', ''] as string[],
        bottomFlop: ['', '', ''] as string[],
        topTurn: '' as string,
        bottomTurn: '' as string,
        topRiver: '' as string,
        bottomRiver: '' as string,
      },
      foldedCards: [] as string[],
      foldedStates: {
        opponents: [false] as boolean[],
        topBoard: false as boolean,
        bottomBoard: false as boolean,
      },
      simulationRuns: (jobInputData.simulation_runs as number) || 1000,
      maxHandCombinations: (jobInputData.max_hand_combinations as number) || 5,
    };

    // Handle board data
    if (
      jobInputData.board &&
      (typeof jobInputData.board === 'string' ||
        Array.isArray(jobInputData.board))
    ) {
      // Single board format - put it in top board
      const board = convertCardsForFrontend(jobInputData.board) as string[];
      spotModeData.communityCards.topFlop = board.slice(0, 3);
      if (board.length > 3) spotModeData.communityCards.topTurn = board[3];
      if (board.length > 4) spotModeData.communityCards.topRiver = board[4];
    } else if (
      jobInputData.top_board &&
      (typeof jobInputData.top_board === 'string' ||
        Array.isArray(jobInputData.top_board))
    ) {
      // Double board format
      const topBoard = convertCardsForFrontend(
        jobInputData.top_board
      ) as string[];
      spotModeData.communityCards.topFlop = topBoard.slice(0, 3);
      if (topBoard.length > 3)
        spotModeData.communityCards.topTurn = topBoard[3];
      if (topBoard.length > 4)
        spotModeData.communityCards.topRiver = topBoard[4];

      if (
        jobInputData.bottom_board &&
        (typeof jobInputData.bottom_board === 'string' ||
          Array.isArray(jobInputData.bottom_board))
      ) {
        const bottomBoard = convertCardsForFrontend(
          jobInputData.bottom_board
        ) as string[];
        spotModeData.communityCards.bottomFlop = bottomBoard.slice(0, 3);
        if (bottomBoard.length > 3)
          spotModeData.communityCards.bottomTurn = bottomBoard[3];
        if (bottomBoard.length > 4)
          spotModeData.communityCards.bottomRiver = bottomBoard[4];
      }
    }

    // Handle players data
    if (jobInputData.players && Array.isArray(jobInputData.players)) {
      const players = jobInputData.players as Array<Record<string, unknown>>;
      if (players.length > 0) {
        // Check if first element is an object with cards property (player objects)
        if (players[0] && typeof players[0] === 'object' && players[0].cards) {
          // Array of player objects
          // First player is hero
          const hero = players[0];
          if (
            hero.cards &&
            (typeof hero.cards === 'string' || Array.isArray(hero.cards))
          ) {
            // Convert cards from short format to emoji format for frontend display
            spotModeData.heroCards = convertCardsForFrontend(
              hero.cards
            ) as string[];
            // Pad to 4 cards if needed
            while (spotModeData.heroCards.length < 4) {
              spotModeData.heroCards.push('');
            }
          }

          // Remaining players are opponents
          const opponents = players.slice(1);
          spotModeData.opponentCards = opponents.map(
            (opp: Record<string, unknown>) => {
              if (
                opp.cards &&
                (typeof opp.cards === 'string' || Array.isArray(opp.cards))
              ) {
                const cards = convertCardsForFrontend(opp.cards) as string[];
                while (cards.length < 4) cards.push('');
                return cards;
              }
              return ['', '', '', ''];
            }
          );

          // Update folded states
          spotModeData.foldedStates.opponents = opponents.map(() => false);
        } else if (Array.isArray(players[0])) {
          // Array of card arrays
          // First player is hero
          if (typeof players[0] === 'string' || Array.isArray(players[0])) {
            spotModeData.heroCards = convertCardsForFrontend(
              players[0]
            ) as string[];
          }
          while (spotModeData.heroCards.length < 4) {
            spotModeData.heroCards.push('');
          }

          // Remaining players are opponents
          spotModeData.opponentCards = players
            .slice(1)
            .map((cards: unknown) => {
              if (typeof cards === 'string' || Array.isArray(cards)) {
                const cardArray = convertCardsForFrontend(cards) as string[];
                while (cardArray.length < 4) cardArray.push('');
                return cardArray;
              }
              return ['', '', '', ''];
            });

          // Update folded states
          spotModeData.foldedStates.opponents = (
            spotModeData.opponentCards as string[][]
          ).map(() => false);
        }
      }
    }

    // Handle folded cards
    if (
      jobInputData.folded_cards &&
      (typeof jobInputData.folded_cards === 'string' ||
        Array.isArray(jobInputData.folded_cards))
    ) {
      spotModeData.foldedCards = convertCardsForFrontend(
        jobInputData.folded_cards
      ) as string[];
    }

    return spotModeData;
  };

  const loadSolverFromJob = async (job: any) => {
    try {
      logDebug(
        '🔍 LoadSolverFromJob: Starting to load solver for job:',
        job.id
      );

      // Fetch full job details to get input_data and result_data
      const response = await api.get(`/jobs/${job.id}/details`);
      const fullJob = response.data.job;

      logDebug('🔍 LoadSolverFromJob: Full job data:', fullJob);
      logDebug('🔍 LoadSolverFromJob: Result data:', fullJob.result_data);

      if (
        fullJob.input_data &&
        (fullJob.job_type === 'solver_simulation' ||
          fullJob.job_type === 'solver_analysis')
      ) {
        // Check if we have solution data to load
        const solutionData =
          fullJob.result_data?.solution || fullJob.result_data;

        if (
          solutionData &&
          (job.status === 'completed' || job.status === 'COMPLETED')
        ) {
          logDebug(
            '🔍 LoadSolverFromJob: Navigating to solver with solution data'
          );

          // Navigate to solver page with both input data and solution
          navigate('/app/solver?tab=solution', {
            state: {
              gameState: fullJob.input_data,
              analysisResults: solutionData,
              fromJobStatus: true,
              activeTab: 'solution', // Force the solution tab to be active
              ts: Date.now(), // ensure state changes even on same route
            },
          });
        } else {
          // If no solution data, just navigate with input data
          logDebug(
            '🔍 LoadSolverFromJob: Navigating to solver with input data only'
          );
          navigate('/app/solver', {
            state: {
              gameState: fullJob.input_data,
              fromJobStatus: true,
              ts: Date.now(),
            },
          });
        }
      } else {
        logError(
          '🔍 LoadSolverFromJob: Invalid job data - missing input_data or wrong job_type'
        );
        toast.warning('Invalid job data for loading solver.');
      }
    } catch (error) {
      logError('🔍 LoadSolverFromJob: Error:', error);
      toast.error('Failed to load solver from job.');
    }
  };

  // merged solver analysis navigation into loadSolverFromJob for consistency

  // JobCard Component
  const JobCard: React.FC<{ job: any }> = ({
    job,
  }) => {
    const isActive =
      job.status === 'queued' ||
      job.status === 'QUEUED' ||
      job.status === 'processing' ||
      job.status === 'PROCESSING';
    const isCompleted =
      job.status === 'completed' ||
      job.status === 'COMPLETED' ||
      job.status === 'failed' ||
      job.status === 'FAILED' ||
      job.status === 'cancelled' ||
      job.status === 'CANCELLED';
    const progressDisplay = getProgressDisplay(job);

    return (
      <div className={`job-card ${isActive ? 'active' : 'completed'}`}>
        <div className="job-header">
          <div className="job-type">
            <span className="job-icon">{getJobTypeDisplay(job.job_type)}</span>
            <span className="job-type-text">
              {job.job_type?.replace('_', ' ')}
            </span>
          </div>
          <div
            className="job-status-actions"
            style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}
          >
            {(job.status === 'completed' || job.status === 'COMPLETED') &&
              typeof job.job_type === 'string' &&
              job.job_type.toLowerCase().includes('spot') && (
                <>
                  <button
                    onClick={() => {
                      logDebug(
                        '🔍 View Results button clicked for job:',
                        job.id,
                        job.job_type,
                        job.status
                      );
                      viewSpotResults(job);
                    }}
                    className="load-results-btn"
                    title="View results for this spot"
                    style={{ marginRight: '0.5rem' }}
                    disabled={loadingResultsId === job.id}
                  >
                    {loadingResultsId === job.id ? 'Loading…' : '👁️ View Results'}
                  </button>
                  <button
                    onClick={() => {
                      logDebug(
                        '🔍 Load Spot button clicked for job:',
                        job.id,
                        job.job_type,
                        job.status
                      );
                      loadSpotFromJob(job);
                    }}
                    className="load-spot-btn"
                    title="Load this spot configuration"
                    style={{ marginRight: '0.5rem' }}
                  >
                    📊 Load Spot
                  </button>
                </>
              )}
            {(job.status === 'completed' || job.status === 'COMPLETED') &&
              (job.job_type === 'solver_simulation' ||
                job.job_type === 'solver_analysis') && (
                <button
                  onClick={() => loadSolverFromJob(job)}
                  className="load-solver-btn"
                  title="Load this solver simulation"
                  style={{ marginRight: '0.5rem' }}
                >
                  🧠 Load Solver
                </button>
              )}
            <span
              className={`status-badge ${isCompleted && (job.status === 'completed' || job.status === 'COMPLETED') ? 'clickable' : ''}`}
              style={{ backgroundColor: getStatusColor(job.status) }}
              onClick={
                isCompleted &&
                (job.status === 'completed' || job.status === 'COMPLETED')
                  ? scrollToResults
                  : undefined
              }
              title={
                isActive
                  ? 'Polling for updates'
                  : job.status === 'completed' || job.status === 'COMPLETED'
                    ? 'Click to view results'
                    : job.status === 'failed' || job.status === 'FAILED'
                      ? `Failed: ${job.error_message || 'Unknown error'}`
                      : 'Job cancelled'
              }
            >
              {getStatusIcon(job.status)} {job.status}
              {isCompleted &&
                (job.status === 'completed' || job.status === 'COMPLETED') && (
                  <span className="view-results-hint">👁️</span>
                )}
            </span>
          </div>
        </div>

        <div className="job-details">
          {/* Progress Bar */}
          <div className="job-progress">
            <div className="progress-bar">
              <div
                className={`progress-fill ${progressDisplay.showPulse ? 'pulse' : ''}`}
                style={{
                  width: `${progressDisplay.percentage}%`,
                  backgroundColor: getStatusColor(job.status),
                }}
              />
            </div>
            <span className="progress-text">{progressDisplay.percentage}%</span>
          </div>

          {/* Progress Message */}
          {progressDisplay.message && (
            <div className="progress-message">{progressDisplay.message}</div>
          )}

          {/* Error Display */}
          {(job.status === 'failed' || job.status === 'FAILED') &&
            job.error_message && (
              <div className="job-error">
                <div className="error-icon">⚠️</div>
                <div className="error-details">
                  <strong>Error:</strong> {job.error_message}
                </div>
              </div>
            )}

          {/* Job Metadata */}
          <div className="job-meta">
            {isActive ? (
              <>
                <span
                  title={`Started at: ${new Date(job.created_at).toLocaleString()}`}
                >
                  Started: {formatActualTimestamp(job.created_at)}
                </span>
                {job.estimated_completion_time && (
                  <span>Est: {formatDuration(job.estimated_duration)}</span>
                )}
              </>
            ) : (
              <>
                <span
                  title={`Completed at: ${new Date(job.completed_at || job.created_at).toLocaleString()}`}
                >
                  Completed:{' '}
                  {formatActualTimestamp(job.completed_at || job.created_at)}
                </span>
                {job.actual_duration && (
                  <span>Duration: {formatDuration(job.actual_duration)}</span>
                )}
                {job.estimated_duration && job.actual_duration && (
                  <span className="estimate-accuracy">
                    {job.actual_duration <= job.estimated_duration
                      ? '✅'
                      : '⏱️'}
                    Est: {formatDuration(job.estimated_duration)}
                  </span>
                )}
              </>
            )}
          </div>

          {/* Job Actions */}
          <div className="job-actions">
            {(job.status === 'queued' || job.status === 'QUEUED' || 
              job.status === 'processing' || job.status === 'PROCESSING') && (
              <button
                onClick={() => cancelJob(job.id)}
                className="cancel-btn"
                title="Cancel this job"
              >
                Cancel
              </button>
            )}
          </div>
        </div>
      </div>
    );
  };

  return (
    <div className="job-status-panel">
      <div className="job-panel-header">
        <h3>🔄 Background Jobs</h3>
        <div className="job-panel-controls">

          <button
            className="refresh-btn"
            onClick={fetchRecentJobs}
            disabled={loading}
            title="Refresh job status"
          >
            🔄
          </button>
          <button
            className="collapse-btn"
            onClick={() => setIsCollapsed(!isCollapsed)}
            title={isCollapsed ? 'Expand panel' : 'Collapse panel'}
          >
            {isCollapsed ? '▶️' : '▼'}
          </button>
        </div>
      </div>

      {!isCollapsed && (
        <>

          {/* Credits Display */}
          {credits && (
            <div className="credits-info">
              <div className="credits-summary">
                <span>Credits: {credits.credits_remaining || 0}</span>
                <span>Jobs: {credits.jobs_remaining || 0}</span>
              </div>
              {credits.subscription_tier && (
                <div className="subscription-info">
                  {credits.subscription_tier} Plan
                </div>
              )}
            </div>
          )}

          {/* Error Display */}
          {error && (
            <div className="error-message">
              <span>{error}</span>
              <button onClick={fetchRecentJobs}>Retry</button>
            </div>
          )}

          {/* Loading State */}
          {loading && jobs.length === 0 && (
            <div className="loading-message">Loading job status...</div>
          )}

          {/* Jobs List */}
          {jobs.length === 0 && !loading && !error && (
            <div className="no-jobs-message">No recent jobs found.</div>
          )}

          {jobs.length > 0 && (() => {
            const totalPages = Math.max(1, Math.ceil(jobs.length / pageSize));
            const safePage = Math.min(currentPage, totalPages);
            const startIdx = (safePage - 1) * pageSize;
            const endIdx = startIdx + pageSize;
            const pageJobs = jobs.slice(startIdx, endIdx);

            return (
              <>
                <div className="jobs-list">
                  {pageJobs.map(job => (
                    <JobCard key={job.id} job={job} />
                  ))}
                </div>

                <div className="jobs-pagination">
                  <button
                    className="page-btn"
                    onClick={() => setCurrentPage(p => Math.max(1, p - 1))}
                    disabled={safePage <= 1}
                    title="Previous page"
                  >
                    ◀ Prev
                  </button>
                  <span className="page-info">
                    Page {safePage} of {totalPages}
                  </span>
                  <button
                    className="page-btn"
                    onClick={() => setCurrentPage(p => Math.min(totalPages, p + 1))}
                    disabled={safePage >= totalPages}
                    title="Next page"
                  >
                    Next ▶
                  </button>
                </div>
              </>
            );
          })()}
        </>
      )}
    </div>
  );
};

export default JobStatusPanel;
