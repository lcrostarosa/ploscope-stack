export interface FaroApi {
  pushEvent?: (name: string, payload?: Record<string, unknown>) => void;
  pushError?: (error: Error, payload?: Record<string, unknown>) => void;
  setUser?: (user: Record<string, unknown>) => void;
}

export type FaroModule = { api?: FaroApi };


