export interface HandHistory {
  id: string;
  filename: string;
  status: string;
  created_at: string;
  processed_hands?: number;
  total_hands?: number;
  poker_site?: string;
  total_profit?: number;
  bb_per_100?: number;
  error_message?: string;
  [key: string]: unknown;
}


