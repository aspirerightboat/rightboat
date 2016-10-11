default_options = Rails.application.config.action_controller.default_url_options

BoatsController.renderer.defaults.merge!(
  http_host: default_options[:host],
  https: Rails.env.production?
)
