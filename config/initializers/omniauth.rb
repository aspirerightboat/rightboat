Rails.application.config.middleware.use OmniAuth::Builder do
  provider :facebook,
           Rails.application.secrets.fb_app_id,
           Rails.application.secrets.fb_app_secret,
           scope: 'email,public_profile',
           info_fields: 'email,name,first_name,last_name,age_range,link,gender,locale,timezone'
end
