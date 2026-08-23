/**
 * Performance Monitor Component
 * Shows Core Web Vitals in development mode
 */

import { useState } from 'react';
import { usePerformance } from '../hooks/usePerformance';
import type { PerformanceMetric } from '../utils/performance';

const getRatingColor = (rating: string): string => {
  switch (rating) {
    case 'good':
      return '#10b981';
    case 'needs-improvement':
      return '#f59e0b';
    case 'poor':
      return '#ef4444';
    default:
      return '#6b7280';
  }
};

const getRatingIcon = (rating: string): string => {
  switch (rating) {
    case 'good':
      return '✓';
    case 'needs-improvement':
      return '~';
    case 'poor':
      return '✗';
    default:
      return '?';
  }
};

export const PerformanceMonitor = ({
  visible = import.meta.env.DEV,
  position = 'bottom-right',
}) => {
  const { metrics, isLoading, measure, getScore, getStatus } = usePerformance({
    autoMeasure: true,
  });

  const [isExpanded, setIsExpanded] = useState(false);

  if (!visible) return null;

  const positionStyles: React.CSSProperties = {
    position: 'fixed',
    zIndex: 9999,
    ...(position.includes('top') ? { top: 10 } : { bottom: 10 }),
    ...(position.includes('left') ? { left: 10 } : { right: 10 }),
  };

  const score = getScore();
  const status = getStatus();

  return (
    <div style={positionStyles}>
      {/* Collapsed View */}
      {!isExpanded && (
        <button
          onClick={() => setIsExpanded(true)}
          style={{
            background: '#1f2937',
            color: '#fff',
            border: 'none',
            borderRadius: 8,
            padding: '8px 12px',
            cursor: 'pointer',
            fontSize: 12,
            fontWeight: 600,
            boxShadow: '0 4px 12px rgba(0,0,0,0.3)',
          }}
        >
          📊 Perf: {score > 0 ? `${score}` : '...'}
        </button>
      )}

      {/* Expanded View */}
      {isExpanded && (
        <div
          style={{
            background: '#1f2937',
            color: '#fff',
            borderRadius: 12,
            padding: 16,
            minWidth: 280,
            boxShadow: '0 8px 24px rgba(0,0,0,0.4)',
            fontFamily: 'monospace',
            fontSize: 12,
          }}
        >
          {/* Header */}
          <div
            style={{
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center',
              marginBottom: 12,
            }}
          >
            <span style={{ fontWeight: 700, fontSize: 14 }}>
              🚀 Core Web Vitals
            </span>
            <button
              onClick={() => setIsExpanded(false)}
              style={{
                background: 'transparent',
                color: '#9ca3af',
                border: 'none',
                cursor: 'pointer',
                fontSize: 16,
              }}
            >
              ×
            </button>
          </div>

          {/* Score Badge */}
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: 8,
              marginBottom: 12,
              padding: '8px 12px',
              background: '#374151',
              borderRadius: 8,
            }}
          >
            <span style={{ fontSize: 24, fontWeight: 700 }}>{score}</span>
            <div>
              <div style={{ fontWeight: 600, textTransform: 'capitalize' }}>
                {status}
              </div>
              <div style={{ color: '#9ca3af', fontSize: 10 }}>
                Overall Score
              </div>
            </div>
          </div>

          {/* Metrics List */}
          {isLoading ? (
            <div style={{ color: '#9ca3af', textAlign: 'center', padding: 16 }}>
              Measuring...
            </div>
          ) : metrics.length > 0 ? (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
              {metrics.map((metric) => (
                <MetricRow key={metric.name} metric={metric} />
              ))}
            </div>
          ) : (
            <div style={{ color: '#9ca3af', textAlign: 'center', padding: 16 }}>
              No metrics available
            </div>
          )}

          {/* Refresh Button */}
          <button
            onClick={() => measure()}
            style={{
              width: '100%',
              marginTop: 12,
              padding: '8px 0',
              background: '#3b82f6',
              color: '#fff',
              border: 'none',
              borderRadius: 6,
              cursor: 'pointer',
              fontWeight: 600,
            }}
          >
            🔄 Re-measure
          </button>
        </div>
      )}
    </div>
  );
};

// Metric Row Component
const MetricRow = ({ metric }: { metric: PerformanceMetric }) => (
  <div
    style={{
      display: 'flex',
      justifyContent: 'space-between',
      alignItems: 'center',
      padding: '6px 10px',
      background: '#374151',
      borderRadius: 6,
    }}
  >
    <span style={{ fontWeight: 500 }}>{metric.name}</span>
    <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
      <span style={{ color: '#d1d5db' }}>
        {metric.value > 0 ? `${metric.value.toFixed(0)}ms` : 'N/A'}
      </span>
      <span
        style={{
          color: getRatingColor(metric.rating),
          fontWeight: 700,
        }}
      >
        {getRatingIcon(metric.rating)}
      </span>
    </div>
  </div>
);

export default PerformanceMonitor;
