ENV['RACK_ENV'] ||= 'development'

require 'bundler/setup'
Bundler.require :default, ENV.fetch('RACK_ENV', nil)

Dir[File.expand_path('config/initializers', __dir__) + '/**/*.rb'].each do |file|
  require file
end

Mongoid.load! File.expand_path('config/mongoid.yml', __dir__), ENV.fetch('RACK_ENV', nil)

require 'slack-ruby-bot'
require 'slack-invite/version'
require 'slack-invite/service'
require 'slack-invite/info'
require 'slack-invite/models'
require 'slack-invite/api'
require 'slack-invite/app'
require 'slack-invite/server'
require 'slack-invite/commands'
