/**
 * React hook for performance monitoring
 */

import { useState, useEffect, useCallback } from 'react';
import {
  measureAllVitals,
  reportVitals,
  type PerformanceMetric,
} from '../utils/performance';

export interface PerformanceState {
  metrics: PerformanceMetric[];
  isLoading: boolean;
  error: Error | null;
}

export interface UsePerformanceOptions {
  /** Auto-measure on mount */
  autoMeasure?: boolean;
  /** Report to analytics endpoint */
  reportEndpoint?: string;
  /** Measure on specific routes */
  measureOnMount?: boolean;
}

/**
 * Hook to measure and track Core Web Vitals
 */
export const usePerformance = (options: UsePerformanceOptions = {}) => {
  const { autoMeasure = true, reportEndpoint, measureOnMount = true } = options;

  const [state, setState] = useState<PerformanceState>({
    metrics: [],
    isLoading: false,
    error: null,
  });

  const measure = useCallback(async () => {
    setState((prev) => ({ ...prev, isLoading: true, error: null }));

    try {
      const metrics = await measureAllVitals();
      setState({ metrics, isLoading: false, error: null });

      // Report if endpoint provided
      if (reportEndpoint) {
        await reportVitals(reportEndpoint);
      }

      return metrics;
    } catch (error) {
      setState((prev) => ({
        ...prev,
        isLoading: false,
        error: error as Error,
      }));
      return [];
    }
  }, [reportEndpoint]);

  useEffect(() => {
    if (autoMeasure && measureOnMount) {
      // Wait for page to fully load
      const timer = setTimeout(() => {
        measure();
      }, 1000);

      return () => clearTimeout(timer);
    }
  }, [autoMeasure, measureOnMount, measure]);

  const getMetricByName = useCallback(
    (name: string) => state.metrics.find((m) => m.name === name),
    [state.metrics]
  );

  const getScore = useCallback(() => {
    if (state.metrics.length === 0) return 0;

    const scores: number[] = state.metrics.map((m) => {
      if (m.rating === 'good') return 100;
      if (m.rating === 'needs-improvement') return 50;
      return 0;
    });

    return Math.round(
      scores.reduce((a, b) => a + b, 0) / scores.length
    );
  }, [state.metrics]);

  const getStatus = useCallback(() => {
    const score = getScore();
    if (score >= 90) return 'excellent';
    if (score >= 70) return 'good';
    if (score >= 50) return 'needs-improvement';
    return 'poor';
  }, [getScore]);

  return {
    ...state,
    measure,
    getMetricByName,
    getScore,
    getStatus,
  };
};

export default usePerformance;
