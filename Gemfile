source 'https://rubygems.org'

ruby '2.2.3'

gem 'rails', '4.2.1'
gem 'mysql2'
gem 'less-rails'
gem 'uglifier', '>= 1.3.0'
gem 'coffee-rails', '~> 4.1.0'
gem 'therubyracer', platforms: :ruby
gem 'less-rails-bootstrap'
gem 'jquery-rails'
gem 'jquery-ui-rails'
# gem 'turbolinks'
gem 'jbuilder', '~> 2.0'
gem 'sdoc', '~> 0.4.0', group: :doc

gem 'haml-rails'
gem 'activeadmin', github: 'activeadmin'
gem 'devise'
gem 'cancan'
gem 'active_model_serializers'
gem 'open_uri_redirections'
gem 'select2-rails'
gem 'kaminari'
gem 'friendly_id'
# This project needs imagemagick to generate captcha!
# on Mac Os run: brew install imagemagick & brew install gs
# on Ubuntu run: sudo apt-get install imagemagick
gem 'carrierwave'
gem 'rmagick' # needed by carrierwave
gem 'fog'
gem 'twitter'
gem 'twitter-text'
gem 'figaro'
gem 'validate_url'
gem 'truncate_html'

# deleted_at
gem 'permanent_records'

# for search
gem 'sunspot_rails'
gem 'sunspot_solr'
gem 'progress_bar', require: false
gem 'sunspot-queue'

# for detecting country
gem 'geocoder'

# background processing & scheduling
gem 'delayed_job_active_record'
gem 'clockwork'

# pdf generating
gem 'wicked_pdf'
gem 'wkhtmltopdf-binary'
gem 'rqrcode'

# for importing module
gem 'mechanize', require: false

# for statistics
gem 'mongo'
gem 'mongoid'
gem 'bson_ext'

gem 'premailer-rails'
gem 'remotipart' # to upload file via ajax
gem 'cocoon'

group :development, :test do
  # gem 'byebug'
  # gem 'web-console', '~> 2.0'
  gem 'spring'
  gem 'puma'
  gem 'capistrano-rvm'
  gem 'capistrano-passenger'
  gem 'capistrano-rails'
  gem 'pry-rails'
#  gem 'mailcatcher'
  gem 'letter_opener'
  gem 'quiet_assets'
  gem 'bullet'
end

group :production, :staging do
  gem 'daemons'
  gem 'passenger'
end

