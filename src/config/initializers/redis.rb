# frozen_string_literal: true

# Redis configuration
# The Redis URL can be configured via the REDIS_URL environment variable
# Default: redis://localhost:6379/0

Rails.application.config.redis = Redis.new(
  url: ENV.fetch("REDIS_URL") { "redis://localhost:6379/0" },
  timeout: 1,
  reconnect_attempts: 3
)
