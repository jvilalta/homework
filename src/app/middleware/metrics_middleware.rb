# frozen_string_literal: true

# Middleware to collect Prometheus metrics
class MetricsMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    Rails.logger.info("MetricsMiddleware: Processing request #{env['REQUEST_METHOD']} #{env['PATH_INFO']}")
    
    start_time = Time.now
    
    begin
      status, headers, body = @app.call(env)
      
      # Record Prometheus metrics
      record_prometheus_metrics(env, status, start_time)
      
      [status, headers, body]
    rescue => e
      # Record error metrics  
      record_prometheus_metrics(env, 500, start_time, error: true)
      raise e
    end
  end

  private

  def record_prometheus_metrics(env, status, start_time, error: false)
    Rails.logger.debug("MetricsMiddleware: Attempting to record Prometheus metrics")
    
    unless defined?(PrometheusConfig)
      Rails.logger.error("MetricsMiddleware: PrometheusConfig not defined!")
      return
    end
    
    Rails.logger.debug("MetricsMiddleware: PrometheusConfig is available")
    
    method = env["REQUEST_METHOD"]
    path = normalize_path(env["PATH_INFO"] || "/")
    status_str = status.to_s
    duration = Time.now - start_time

    Rails.logger.debug("MetricsMiddleware: Recording metrics for #{method} #{path} - Status: #{status}, Duration: #{duration}s")

    begin
      # Record HTTP requests counter
      PrometheusConfig::HTTP_REQUESTS_TOTAL.increment(
        labels: {
          method: method.downcase,
          path: path,
          status: status_str
        }
      )
      Rails.logger.debug("MetricsMiddleware: HTTP_REQUESTS_TOTAL incremented")

      # Record request duration histogram
      PrometheusConfig::REQUEST_DURATION_SECONDS.observe(
        duration,
        labels: {
          method: method.downcase,
          path: path,
          status: status_str
        }
      )
      Rails.logger.debug("MetricsMiddleware: REQUEST_DURATION_SECONDS recorded")

      Rails.logger.debug("MetricsMiddleware: Successfully recorded Prometheus metrics for #{method} #{path} - Status: #{status}, Duration: #{duration}s")
    rescue => e
      Rails.logger.error("MetricsMiddleware: Error recording Prometheus metrics: #{e.message}")
      Rails.logger.error("MetricsMiddleware: Error backtrace: #{e.backtrace.join('\n')}")
    end
  end

  def normalize_path(path)
    # Normalize paths to reduce cardinality
    # Replace IDs and UUIDs with placeholders
    normalized = path.dup
    normalized.gsub!(/\/\d+/, '/:id')  # Replace numeric IDs
    normalized.gsub!(/\/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/i, '/:uuid')  # Replace UUIDs
    normalized
  end
end
