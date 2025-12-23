# Prometheus Metrics Integration

This Rails application has been configured with Prometheus metrics export capabilities.

## Metrics Available

The application exposes the following Prometheus metrics:

### HTTP Request Metrics

- **`http_requests_total`** - Counter tracking total number of HTTP requests
  - Labels: `method`, `path`, `status`
  
- **`request_duration_seconds`** - Histogram tracking HTTP request duration in seconds
  - Labels: `method`, `path`, `status`
  - Buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10]

### Application Metrics

- **`active_connections`** - Gauge showing number of active connections

- **`rails_info`** - Gauge providing Rails application information
  - Labels: `version`, `environment`

## Metrics Endpoint

The metrics are available at:
```
GET /metrics
```

This endpoint returns metrics in Prometheus format that can be scraped by Prometheus servers.

## Example Prometheus Configuration

Add the following to your `prometheus.yml` configuration:

```yaml
scrape_configs:
  - job_name: 'rails-app'
    static_configs:
      - targets: ['localhost:3000']  # Adjust port as needed
    scrape_interval: 15s
    metrics_path: /metrics
```

## Path Normalization

To prevent high cardinality metrics, the middleware automatically normalizes request paths:
- Numeric IDs are replaced with `:id` (e.g., `/users/123` → `/users/:id`)
- UUIDs are replaced with `:uuid`

## Metrics Export

This application uses **Prometheus** metrics for comprehensive observability:
- HTTP request counters with method, path, and status labels
- Request duration histograms with configurable buckets
- Active connections gauge
- Rails application information

## Testing the Integration

1. Start the Rails application:
   ```bash
   rails server
   ```

2. Make some requests to generate metrics:
   ```bash
   curl http://localhost:3000/
   curl http://localhost:3000/up
   ```

3. Check the metrics endpoint:
   ```bash
   curl http://localhost:3000/metrics
   ```

You should see Prometheus-formatted metrics including the request counts and durations for the requests you made.
