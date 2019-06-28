require_relative 'boot'

require 'rails/all'

Bundler.require(*Rails.groups)

module Tabekiri
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2
    config.time_zone = 'Tokyo'
    config.i18n.default_locale = :ja
  end
end
