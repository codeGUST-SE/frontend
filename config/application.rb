require File.expand_path("../boot", __FILE__)

require "rails"

# Pick the frameworks you want:
require "active_model/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "sprockets/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module CodeGustFrontendApp
  class Application < Rails::Application
    config.eager_load_paths += %W(#{config.root}/lib/current_block_queue)
    config.eager_load_paths += %W(#{config.root}/lib/document_retrieval)
  end
end
