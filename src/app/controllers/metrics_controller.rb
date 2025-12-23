# frozen_string_literal: true

# Controller to expose Prometheus metrics
class MetricsController < ApplicationController
  # Skip CSRF protection for metrics endpoint
  skip_forgery_protection

  def index
    # Expose metrics in Prometheus format
    # Generate the simple text output for now
    output = []
    
    Rails.logger.info "MetricsController: Generating metrics output"
    Rails.logger.info "MetricsController: Registry has #{PrometheusConfig::REGISTRY.metrics.count} metrics"
    
    # Rails info metric
    output << "# HELP rails_info Rails application information"
    output << "# TYPE rails_info gauge"
    output << "rails_info{version=\"#{Rails.version}\",environment=\"#{Rails.env}\"} 1"
    
    # Get current metrics
    PrometheusConfig::REGISTRY.metrics.each_with_index do |metric, index|
      Rails.logger.info "MetricsController: Processing metric #{index}: #{metric.name} (#{metric.class})"
      begin
        case metric
        when Prometheus::Client::Counter
          output << "# HELP #{metric.name} #{metric.docstring}"
          output << "# TYPE #{metric.name} counter"
          Rails.logger.info "MetricsController: Counter #{metric.name} has #{metric.values.count} values"
          metric.values.each do |labels, value|
            label_str = labels.map { |k, v| "#{k}=\"#{v}\"" }.join(',')
            output << "#{metric.name}{#{label_str}} #{value}"
          end
        when Prometheus::Client::Histogram
          output << "# HELP #{metric.name} #{metric.docstring}"
          output << "# TYPE #{metric.name} histogram"
          Rails.logger.info "MetricsController: Histogram #{metric.name} has #{metric.values.count} values"
          metric.values.each do |labels, value|
            label_str = labels.map { |k, v| "#{k}=\"#{v}\"" }.join(',')
            value.each do |bucket, count|
              if bucket == '+Inf'
                output << "#{metric.name}_bucket{#{label_str},le=\"+Inf\"} #{count}"
              else
                output << "#{metric.name}_bucket{#{label_str},le=\"#{bucket}\"} #{count}"
              end
            end
          end
        when Prometheus::Client::Gauge
          output << "# HELP #{metric.name} #{metric.docstring}"
          output << "# TYPE #{metric.name} gauge"
          Rails.logger.info "MetricsController: Gauge #{metric.name} has #{metric.values.count} values"
          metric.values.each do |labels, value|
            label_str = labels.map { |k, v| "#{k}=\"#{v}\"" }.join(',')
            output << "#{metric.name}{#{label_str}} #{value}"
          end
        end
      rescue => e
        Rails.logger.error("Error formatting metric #{metric.name}: #{e.message}")
      end
    end
    
    Rails.logger.info "MetricsController: Generated #{output.count} lines of output"
    
    render plain: output.join("\n"), content_type: 'text/plain; version=0.0.4; charset=utf-8'
  end
end
