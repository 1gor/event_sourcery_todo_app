# frozen_string_literal: true

source 'https://rubygems.org'

gem 'event_sourcery'
gem 'event_sourcery-postgres'#, path: '/home/id/Src/events/event_sourcery-postgres-0.8.0'

gem 'rake'
gem 'sinatra'
# NOTE: pg is an implicit dependency of event_sourcery-postgres but we need to
# lock to an older version for deprecation warnings.
gem 'pg'#, '0.20.0'

group :development, :test do
  gem 'pry-byebug'
  gem 'rspec'
  gem 'rack-test'
  gem 'database_cleaner-sequel'
  gem 'shotgun'
  gem 'commander'
  gem 'better_errors'
end
