/* eslint-disable */
import { trackEvent, trackPageView } from '../../src/utils/analytics';

describe('Analytics telemetry throttling and backoff', () => {
  const originalFetch = global.fetch as any;
  const originalLocalStorage = global.localStorage;

  beforeEach(() => {
    // Allow analytics by default
    const store: Record<string, string> = {
      cookieConsent: JSON.stringify({ analytics: true }),
    };
    global.localStorage = {
      getItem: (k: string) => store[k] ?? null,
      setItem: (k: string, v: string) => {
        store[k] = v;
      },
      removeItem: (k: string) => {
        delete store[k];
      },
      clear: () => {
        Object.keys(store).forEach(k => delete store[k]);
      },
      key: (i: number) => Object.keys(store)[i] ?? null,
      length: 1,
    } as any;
  });

  afterEach(() => {
    global.fetch = originalFetch;
    global.localStorage = originalLocalStorage;
    jest.useRealTimers();
    jest.clearAllMocks();
  });

  it('throttles rapid duplicate events', async () => {
    const fetchSpy = jest
      .fn()
      .mockResolvedValue({ status: 204, headers: new Headers() });
    global.fetch = fetchSpy;

    trackEvent('form_field_change', { field_name: 'x' });
    trackEvent('form_field_change', { field_name: 'x' });
    trackEvent('form_field_change', { field_name: 'x' });

    // Only first should pass immediately
    await new Promise(r => setTimeout(r, 10));
    expect(fetchSpy).toHaveBeenCalledTimes(1);
  });

  it('applies backoff after 429', async () => {
    jest.useFakeTimers();
    const headers = new Headers({ 'Retry-After': '1' }); // 1 second
    const fetchSpy = jest
      .fn()
      .mockResolvedValueOnce({ status: 429, headers }) // trigger backoff
      .mockResolvedValue({ status: 204, headers: new Headers() });
    global.fetch = fetchSpy;

    trackPageView('/x', 'x');
    await Promise.resolve();

    // During backoff, events should be dropped
    trackEvent('user_engagement', { foo: 'bar' });
    trackEvent('user_engagement', { foo: 'bar' });

    // Fast-forward less than retry window
    jest.advanceTimersByTime(500);
    await Promise.resolve();
    expect(fetchSpy).toHaveBeenCalledTimes(1);

    // After retry window, events can go out again
    jest.advanceTimersByTime(600);
    trackEvent('user_engagement', { foo: 'bar' });
    await Promise.resolve();
    expect(fetchSpy).toHaveBeenCalledTimes(2);
  });
});
