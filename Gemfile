source 'https://rubygems.org'
git_source(:github) { |repo_name| "https://github.com/#{repo_name}.git" }

gem 'rails', '~> 4.2.6'

gem 'activerecord-session_store'
gem 'ahoy_matey'
gem 'browserify-rails'
gem 'coffee-rails', '~> 4.1.0'
gem 'devise', '~> 4.1'
gem 'dotiw'
gem 'figaro'
gem 'foundation_emails'
gem 'gyoku'
gem 'hashie'
gem 'hiredis'
gem 'httparty'
gem 'lograge'
gem 'newrelic_rpm'
gem 'omniauth-saml'
gem 'phony_rails'
gem 'pg'
gem 'premailer-rails'
gem 'proofer', github: '18F/identity-proofer-gem', branch: 'master'
gem 'pundit'
gem 'valid_email'
gem 'rack-attack'
gem 'readthis'
gem 'rqrcode'

# unreleased feature via: https://github.com/onelogin/ruby-saml/pull/345
gem 'ruby-saml', github: 'onelogin/ruby-saml', branch: 'master'

gem 'saml_idp', '~> 0.4.0'
gem 'sass-rails', '~> 5.0'
gem 'savon'
gem 'secure_headers', '~> 3.0'
gem 'sidekiq'
gem 'simple_form'
gem 'sinatra', require: false
gem 'slim-rails'
gem 'split', require: 'split/dashboard'
gem 'twilio-ruby'
gem 'two_factor_authentication', github: 'Houdini/two_factor_authentication', ref: '1d6abe3'
gem 'uglifier', '>= 1.3.0'
gem 'whenever', require: false
gem 'xmlenc', '~> 0.6.4'
gem 'xml-simple'

group :deploy do
  gem 'capistrano'
  gem 'capistrano-rails'
  gem 'capistrano-rbenv'
  gem 'capistrano-sidekiq'
end

group :development do
  gem 'better_errors'
  gem 'brakeman', require: false
  gem 'bummr', require: false
  gem 'derailed'
  gem 'binding_of_caller'
  gem 'guard-rspec', require: false
  gem 'overcommit', require: false
  gem 'quiet_assets'
  gem 'rack-mini-profiler'
  gem 'rails_layout'
  gem 'reek'
  gem 'rubocop', require: false
  gem 'spring'
  gem 'spring-commands-rspec'
  gem 'spring-watcher-listen'
end

group :development, :test do
  gem 'bullet'
  gem 'i18n-tasks'
  gem 'mailcatcher', require: false
  gem 'pry-byebug'
  gem 'rspec-rails', '~> 3.3'
  gem 'slim_lint'
  gem 'thin'
end

group :test do
  gem 'capybara-screenshot'
  gem 'codeclimate-test-reporter', require: false
  gem 'database_cleaner'
  gem 'email_spec'
  gem 'factory_girl_rails'
  gem 'faker'
  gem 'poltergeist'
  gem 'rack_session_access'
  gem 'rack-test'
  gem 'shoulda-matchers', '~> 2.8', require: false
  gem 'test_after_commit'
  gem 'timecop'
  gem 'webmock'
end
