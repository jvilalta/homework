require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module RorPoc
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])
    
    # Autoload middleware directory
    config.autoload_paths += %W[#{config.root}/app/middleware]

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Add MetricsMiddleware to the stack - this is the correct way in Rails 8.1
    # Skip during asset precompilation to avoid loading middleware unnecessarily
    # unless ENV['RAILS_PRECOMPILE'] == 'true' || (defined?(Rake) && defined?(Rake.application))
      # Explicitly require the middleware
      require_relative '../app/middleware/metrics_middleware'
      config.middleware.use MetricsMiddleware
    # end
  end
end
