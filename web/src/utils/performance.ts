/**
 * Performance monitoring utilities for StudioBook Web
 */

// Core Web Vitals thresholds
export const THRESHOLDS = {
  FCP: 2000,  // First Contentful Paint
  LCP: 2500,  // Largest Contentful Paint
  CLS: 0.1,   // Cumulative Layout Shift
  TBT: 300,   // Total Blocking Time
  TTI: 3500,  // Time to Interactive
  SI: 3000,   // Speed Index
} as const;

// Performance metric types
export interface PerformanceMetric {
  name: string;
  value: number;
  rating: 'good' | 'needs-improvement' | 'poor';
  timestamp: number;
}

// Check if Performance API is available
const isPerformanceAvailable = (): boolean =>
  typeof window !== 'undefined' && 'performance' in window;

// Get current timestamp
const getTimestamp = (): number => Date.now();

// Rate a metric based on thresholds
const rateMetric = (
  name: string,
  value: number
): 'good' | 'needs-improvement' | 'poor' => {
  const threshold = THRESHOLDS[name as keyof typeof THRESHOLDS];
  if (!threshold) return 'good';

  if (value <= threshold * 0.7) return 'good';
  if (value <= threshold) return 'needs-improvement';
  return 'poor';
};

/**
 * Measure First Contentful Paint
 */
export const measureFCP = (): Promise<PerformanceMetric> => {
  return new Promise((resolve) => {
    if (!isPerformanceAvailable()) {
      resolve({
        name: 'FCP',
        value: 0,
        rating: 'good',
        timestamp: getTimestamp(),
      });
      return;
    }

    const observer = new PerformanceObserver((list) => {
      const entries = list.getEntries();
      const fcpEntry = entries.find(
        (entry) => entry.name === 'first-contentful-paint'
      );

      if (fcpEntry) {
        resolve({
          name: 'FCP',
          value: fcpEntry.startTime,
          rating: rateMetric('FCP', fcpEntry.startTime),
          timestamp: getTimestamp(),
        });
      }
    });

    observer.observe({ type: 'paint', buffered: true });

    // Fallback if no entry found
    setTimeout(() => {
      resolve({
        name: 'FCP',
        value: 0,
        rating: 'good',
        timestamp: getTimestamp(),
      });
    }, 5000);
  });
};

/**
 * Measure Largest Contentful Paint
 */
export const measureLCP = (): Promise<PerformanceMetric> => {
  return new Promise((resolve) => {
    if (!isPerformanceAvailable()) {
      resolve({
        name: 'LCP',
        value: 0,
        rating: 'good',
        timestamp: getTimestamp(),
      });
      return;
    }

    let lcpValue = 0;

    const observer = new PerformanceObserver((list) => {
      const entries = list.getEntries();
      const lastEntry = entries[entries.length - 1];
      if (lastEntry) {
        lcpValue = lastEntry.startTime;
      }
    });

    observer.observe({ type: 'largest-contentful-paint', buffered: true });

    // Resolve after page load
    window.addEventListener(
      'load',
      () => {
        setTimeout(() => {
          resolve({
            name: 'LCP',
            value: lcpValue,
            rating: rateMetric('LCP', lcpValue),
            timestamp: getTimestamp(),
          });
        }, 1000);
      },
      { once: true }
    );
  });
};

/**
 * Measure Cumulative Layout Shift
 */
export const measureCLS = (): Promise<PerformanceMetric> => {
  return new Promise((resolve) => {
    if (!isPerformanceAvailable()) {
      resolve({
        name: 'CLS',
        value: 0,
        rating: 'good',
        timestamp: getTimestamp(),
      });
      return;
    }

    let clsValue = 0;

    const observer = new PerformanceObserver((list) => {
      for (const entry of list.getEntries()) {
        if (!(entry as any).hadRecentInput) {
          clsValue += (entry as any).value;
        }
      }
    });

    observer.observe({ type: 'layout-shift', buffered: true });

    // Resolve after page load
    window.addEventListener(
      'load',
      () => {
        setTimeout(() => {
          resolve({
            name: 'CLS',
            value: clsValue,
            rating: rateMetric('CLS', clsValue),
            timestamp: getTimestamp(),
          });
        }, 1000);
      },
      { once: true }
    );
  });
};

/**
 * Measure Total Blocking Time
 */
export const measureTBT = (): Promise<PerformanceMetric> => {
  return new Promise((resolve) => {
    if (!isPerformanceAvailable()) {
      resolve({
        name: 'TBT',
        value: 0,
        rating: 'good',
        timestamp: getTimestamp(),
      });
      return;
    }

    let tbtValue = 0;

    const observer = new PerformanceObserver((list) => {
      for (const entry of list.getEntries()) {
        if (entry.duration > 50) {
          tbtValue += entry.duration - 50;
        }
      }
    });

    observer.observe({ type: 'longtask', buffered: true });

    // Resolve after page load
    window.addEventListener(
      'load',
      () => {
        setTimeout(() => {
          resolve({
            name: 'TBT',
            value: tbtValue,
            rating: rateMetric('TBT', tbtValue),
            timestamp: getTimestamp(),
          });
        }, 1000);
      },
      { once: true }
    );
  });
};

/**
 * Measure Time to Interactive
 */
export const measureTTI = (): Promise<PerformanceMetric> => {
  return new Promise((resolve) => {
    if (!isPerformanceAvailable()) {
      resolve({
        name: 'TTI',
        value: 0,
        rating: 'good',
        timestamp: getTimestamp(),
      });
      return;
    }

    // Use navigation timing as approximation
    const navigationEntry = performance.getEntriesByType(
      'navigation'
    )[0] as PerformanceNavigationTiming;

    if (navigationEntry) {
      const tti = navigationEntry.loadEventEnd - navigationEntry.startTime;
      resolve({
        name: 'TTI',
        value: tti,
        rating: rateMetric('TTI', tti),
        timestamp: getTimestamp(),
      });
    } else {
      resolve({
        name: 'TTI',
        value: 0,
        rating: 'good',
        timestamp: getTimestamp(),
      });
    }
  });
};

/**
 * Measure all Core Web Vitals
 */
export const measureAllVitals = async (): Promise<PerformanceMetric[]> => {
  const [fcp, lcp, cls, tbt, tti] = await Promise.all([
    measureFCP(),
    measureLCP(),
    measureCLS(),
    measureTBT(),
    measureTTI(),
  ]);

  return [fcp, lcp, cls, tbt, tti];
};

/**
 * Log performance metrics to console (development only)
 */
export const logVitals = async (): Promise<void> => {
  if (import.meta.env.DEV) {
    const metrics = await measureAllVitals();
    console.group('🚀 Core Web Vitals');
    metrics.forEach((metric) => {
      const icon =
        metric.rating === 'good'
          ? '✅'
          : metric.rating === 'needs-improvement'
            ? '⚠️'
            : '❌';
      console.log(
        `${icon} ${metric.name}: ${metric.value.toFixed(2)}ms (${metric.rating})`
      );
    });
    console.groupEnd();
  }
};

/**
 * Send metrics to analytics endpoint
 */
export const reportVitals = async (
  endpoint?: string
): Promise<void> => {
  const metrics = await measureAllVitals();

  const payload = {
    url: window.location.href,
    userAgent: navigator.userAgent,
    timestamp: getTimestamp(),
    metrics: metrics.reduce(
      (acc, metric) => ({
        ...acc,
        [metric.name]: {
          value: metric.value,
          rating: metric.rating,
        },
      }),
      {}
    ),
  };

  // Log in development
  if (import.meta.env.DEV) {
    console.log('📊 Vital Metrics:', payload);
  }

  // Send to analytics endpoint if provided
  if (endpoint) {
    try {
      await fetch(endpoint, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
        keepalive: true,
      });
    } catch (error) {
      console.error('Failed to report vitals:', error);
    }
  }
};

export default {
  measureFCP,
  measureLCP,
  measureCLS,
  measureTBT,
  measureTTI,
  measureAllVitals,
  logVitals,
  reportVitals,
  THRESHOLDS,
};
