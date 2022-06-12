$LOAD_PATH.unshift(File.dirname(__FILE__))

ENV['RACK_ENV'] ||= 'development'

require 'bundler/setup'
Bundler.require :default, ENV['RACK_ENV']

require 'slack-ruby-bot-server-rtm'
require 'slack-invite'

SlackRubyBotServer.configure do |config|
  config.server_class = SlackInvite::Server
end

NewRelic::Agent.manual_start

SlackInvite::App.instance.prepare!

Thread.abort_on_exception = true

Thread.new do
  SlackRubyBotServer::Service.instance.start_from_database!
  SlackInvite::App.instance.after_start!
end

run Api::Middleware.instance
