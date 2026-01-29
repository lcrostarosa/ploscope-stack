export interface TelemetryBody {
  event_name: string;
  event_time: string;
  page_path?: string;
  analytics_id?: string;
  properties?: Record<string, unknown>;
}


