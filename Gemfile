source 'https://rubygems.org'

ruby '2.3.0'

gem 'rails', '4.2.6'
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

gem 'slim-rails'
gem 'activeadmin', github: 'activeadmin'
gem 'devise'
gem 'cancan'
gem 'active_model_serializers'
gem 'open_uri_redirections'
gem 'kaminari'
gem 'friendly_id'
# rmagick requires dependencies:
# on Mac Os run: brew install imagemagick & brew install gs
# on Mac Os run: xcode-select --install
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
gem 'progress_bar', require: false
gem 'sunspot-queue'
gem 'sitemap_generator'

# for detecting country
gem 'geocoder'

# background processing & scheduling
gem 'delayed_job_active_record'
gem 'delayed_job_web'

# pdf generating
gem 'wicked_pdf' # you need install wkhtmltopdf binary manually to have the latest version. see: http://wkhtmltopdf.org/downloads.html
gem 'rqrcode'

# for importing module
gem 'mechanize', require: false

# for statistics
gem 'mongo'
gem 'mongoid'
gem 'bson_ext'

gem 'premailer-rails'
#gem 'remotipart' # to upload file via ajax
gem 'cocoon'

gem 'redis-rails'

gem 'xeroizer'
gem 'xxhash' # calc simple hash 10x faster than Digest::SHA1.hexdigest
gem 'ruby-filemagic' # determine mime-type by file content. requires "brew install libmagic" on OS X and "apt-get install libmagic-dev" on Ubuntu

gem 'rails4-autocomplete'

gem 'whenever', require: false

group :development, :test do
  gem 'spring'
  gem 'puma'
  gem 'capistrano-rvm'
  gem 'capistrano-passenger'
  gem 'capistrano-rails'
  gem 'capistrano-db-tasks', require: false # bundle exec cap production db:pull
  gem 'capistrano-secrets-yml' # cap production setup
  gem 'airbrussh', require: false
  gem 'pry-rails'
  gem 'letter_opener'
  gem 'quiet_assets'
  gem 'bullet'
  gem 'pry-byebug'
  gem 'wkhtmltopdf-binary'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'haml2slim'
end

group :test do
  gem 'rspec-rails'
  gem 'factory_girl'
  gem 'email_spec'
  gem 'rspec-json_expectations'
  gem 'database_cleaner'
  gem 'capybara'
  gem 'nokogiri'
end

group :development, :staging do
  gem 'sunspot_solr'
end

group :production, :staging do
  gem 'daemons'
end

