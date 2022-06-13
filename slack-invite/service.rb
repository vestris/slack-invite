module SlackRubyBotServer
  class Service
    def self.url
      ENV.fetch('URL') { (ENV['RACK_ENV'] == 'development' ? 'http://localhost:5000' : 'https://invite.playplay.io') }
    end
  end
end
