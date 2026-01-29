import {
  __setFaroApiForTest,
  __setInitializedForTest,
  trackEvent,
  trackPageView,
  identifyUser,
} from '../../src/utils/analytics';

describe('Grafana Faro integration', () => {
  beforeEach(() => {
    jest.resetModules();
    __setInitializedForTest(true);
  });

  it('pushes custom events to Faro when available', () => {
    const pushEvent = jest.fn();
    __setFaroApiForTest({ pushEvent });

    trackEvent('unit_test_event', { foo: 'bar' });

    expect(pushEvent).toHaveBeenCalledWith(
      'unit_test_event',
      expect.objectContaining({ foo: 'bar' })
    );
  });

  it('pushes page views to Faro', () => {
    const pushEvent = jest.fn();
    __setFaroApiForTest({ pushEvent });

    trackPageView('/test', 'Test Page');

    expect(pushEvent).toHaveBeenCalledWith(
      'page_view',
      expect.objectContaining({ page_path: '/test', page_title: 'Test Page' })
    );
  });

  it('does not set user id on Faro identify (GDPR: no PII)', () => {
    const setUser = jest.fn();
    __setFaroApiForTest({ setUser });

    identifyUser();

    expect(setUser).not.toHaveBeenCalled();
  });
});
