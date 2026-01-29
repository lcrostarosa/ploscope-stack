export {};

declare global {
  interface Window {
    gtag?: (...args: unknown[]) => void;
    dataLayer?: unknown[];
    // Clarity and PostHog removed
    fbq?: (...args: unknown[]) => void;
    analytics?: unknown;
    // Grafana Faro
    faro?: unknown;
    // react-helmet ambient if types missing
    // eslint-disable-next-line @typescript-eslint/ban-types
    Helmet?: Function;
    webpackChunkload?: unknown;
  }
}

declare module 'react-helmet';

declare module '*.mdx' {
  import type { FC } from 'react';
  const MDXComponent: FC<Record<string, unknown>>;
  export const meta: Record<string, unknown> | undefined;
  export default MDXComponent;
}
