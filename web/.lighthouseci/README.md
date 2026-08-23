# Lighthouse CI Configuration

## Overview

Lighthouse CI is configured to automatically test web performance on every build.

## Configuration Files

| File | Description |
|------|-------------|
| `lighthouserc.json` | Main Lighthouse CI configuration |
| `budget.json` | Performance budget thresholds |
| `package.json` | Lighthouse scripts |

## Performance Budget

### Timing Metrics

| Metric | Budget | Description |
|--------|--------|-------------|
| First Contentful Paint (FCP) | < 2.0s | Time to first content |
| Largest Contentful Paint (LCP) | < 2.5s | Time to largest content |
| Cumulative Layout Shift (CLS) | < 0.1 | Layout stability |
| Total Blocking Time (TBT) | < 300ms | Interactivity delay |
| Interactive (TTI) | < 3.5s | Time to interactive |
| Speed Index | < 3.0s | Visual completeness |

### Resource Budgets

| Resource Type | Size Budget | Count Budget |
|---------------|-------------|--------------|
| Total | 500 KB | 50 |
| Scripts | 300 KB | 10 |
| Stylesheets | 50 KB | 5 |
| Images | 200 KB | 20 |
| Fonts | 100 KB | 5 |

### Category Scores

| Category | Minimum Score |
|----------|---------------|
| Performance | 80% |
| Accessibility | 90% |
| Best Practices | 90% |
| SEO | 90% |

## Running Lighthouse Locally

```bash
cd web

# Install dependencies
npm ci

# Build the app
npm run build

# Run Lighthouse
npm run lighthouse

# Run with specific config
npx lhci autorun --config=lighthouserc.json
```

## CI Pipeline Integration

Lighthouse runs automatically in the CI pipeline:

1. **Build** - Web app is built
2. **Collect** - Lighthouse runs 3 times on desktop preset
3. **Assert** - Results are checked against budgets
4. **Upload** - Results uploaded to temporary storage

### GitHub Actions

```yaml
- name: Lighthouse CI
  uses: treosh/lighthouse-ci-action@v12
  with:
    working-dir: web
    configPath: ./lighthouserc.json
    uploadArtifacts: true
    temporaryPublicStorage: true
```

## Viewing Results

### CI Artifacts

Results are uploaded as artifacts:
- `lighthouse-results/` - Contains HTML reports
- Available for 30 days

### Temporary Public Storage

Results are also uploaded to Google's temporary public storage:
- Link available in CI logs
- Expires after 7 days

## Optimization Tips

### If Performance Score is Low

1. **Reduce JavaScript**
   - Code split routes
   - Lazy load components
   - Remove unused code

2. **Optimize Images**
   - Use WebP format
   - Implement lazy loading
   - Compress images

3. **Improve Caching**
   - Set proper cache headers
   - Use service workers
   - Implement CDN

4. **Reduce Layout Shifts**
   - Set image dimensions
   - Reserve space for ads
   - Use CSS contain

### If Accessibility Score is Low

1. Add alt text to images
2. Ensure proper heading hierarchy
3. Add ARIA labels
4. Check color contrast
5. Make forms accessible

### If SEO Score is Low

1. Add meta descriptions
2. Use proper title tags
3. Add structured data
4. Create sitemap
5. Use canonical URLs

## Troubleshooting

### Lighthouse Fails to Run

```bash
# Clear cache
rm -rf node_modules/.cache
rm -rf .lighthouseci

# Reinstall
npm ci

# Try again
npm run lighthouse
```

### Low Scores in CI

CI environments may have lower scores due to:
- Shared resources
- Network variability
- No GPU acceleration

Consider:
- Running more iterations
- Using faster runners
- Adjusting thresholds for CI

## References

- [Lighthouse CI Documentation](https://github.com/GoogleChrome/lighthouse-ci)
- [Lighthouse Scoring](https://developer.chrome.com/docs/lighthouse/performance/scoring)
- [Web Vitals](https://web.dev/vitals/)
