export interface Job {
  id: string | number;
  status: string;
  created_at?: string;
  updated_at?: string;
  completed_at?: string;
  job_type?:
    | 'spot_simulation'
    | 'analysis_simulation'
    | 'spot_analysis'
    | string;
  progress?: number;
  progress_percentage?: number;
  progress_message?: string;
  result?: unknown;
  result_data?: unknown;
  input_data?: unknown;
  error?: string;
  error_message?: string;
  estimated_duration?: number;
  actual_duration?: number;
  estimated_completion_time?: string;
  [key: string]: unknown;
}

export interface CreditsInfo {
  credits_remaining?: number;
  jobs_remaining?: number;
  subscription_tier?: string;
  [key: string]: unknown;
}

export interface JobUpdatePayload {
  job_id: string | number;
  update?: Partial<Job>;
  [key: string]: unknown;
}
