if Rightboat::Application.config.action_mailer&.delivery_method == :smtp
  if (options = YAML.load_file(Rails.root.join('config', 'smtp.yml'))[Rails.env]).present?
    Rightboat::Application.config.action_mailer.smtp_settings = {}
    options.each do |name, value|
      Rightboat::Application.config.action_mailer.smtp_settings[name.to_sym] = value
    end
  end
end
