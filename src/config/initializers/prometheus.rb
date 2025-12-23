# frozen_string_literal: true

require 'prometheus/client'

# Configure Prometheus metrics
module PrometheusConfig
  # Initialize Prometheus registry
  REGISTRY = Prometheus::Client.registry

  # Define metrics
  HTTP_REQUESTS_TOTAL = Prometheus::Client::Counter.new(
    :http_requests_total,
    docstring: 'Total number of HTTP requests',
    labels: [:method, :path, :status]
  )

  REQUEST_DURATION_SECONDS = Prometheus::Client::Histogram.new(
    :request_duration_seconds,
    docstring: 'HTTP request duration in seconds',
    labels: [:method, :path, :status],
    buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10]
  )

  ACTIVE_CONNECTIONS = Prometheus::Client::Gauge.new(
    :active_connections,
    docstring: 'Number of active connections'
  )

  RAILS_INFO = Prometheus::Client::Gauge.new(
    :rails_info,
    docstring: 'Rails application information',
    labels: [:version, :environment]
  )

  # Register metrics
  REGISTRY.register(HTTP_REQUESTS_TOTAL)
  REGISTRY.register(REQUEST_DURATION_SECONDS)
  REGISTRY.register(ACTIVE_CONNECTIONS)
  REGISTRY.register(RAILS_INFO)

  # Set Rails info metric
  RAILS_INFO.set(
    1,
    labels: {
      version: Rails.version,
      environment: Rails.env
    }
  )
end
