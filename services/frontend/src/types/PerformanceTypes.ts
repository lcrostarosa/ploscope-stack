// Performance monitoring related types

export interface PerformanceMetric {
  label: string;
  category: string;
  duration: number;
  startTime: number;
  endTime: number;
  id: string;
  success?: boolean;
  statusCode?: number | null;
  url?: string;
  method?: string;
}

export interface ApiMonitorReturn {
  end: (success?: boolean, results?: unknown) => void;
}

export interface InteractionMonitorReturn {
  end: (success?: boolean) => void;
}

export interface SimulationMonitorReturn {
  end: (success?: boolean, results?: unknown) => void;
}

export interface PerfOptions {
  trackRenders?: boolean;
  trackProps?: boolean;
  threshold?: number;
  trackInteractions?: boolean;
  trackApiCalls?: boolean;
  trackSimulations?: boolean;
  thresholds?: Record<string, number>;
  enableReporting?: boolean;
  sampleRate?: number;
}

export interface PerformanceThresholds {
  api: number;
  interaction: number;
  simulation: number;
  render: number;
  [key: string]: number;
}

export interface PerformanceReport {
  timestamp: number;
  metrics: PerformanceMetric[];
  summary: {
    totalMetrics: number;
    averageDuration: number;
    slowestMetric: PerformanceMetric | null;
    fastestMetric: PerformanceMetric | null;
    errorRate: number;
  };
  environment: {
    userAgent: string;
    url: string;
    timestamp: number;
  };
}
