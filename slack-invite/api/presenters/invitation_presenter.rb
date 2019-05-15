module Api
  module Presenters
    module InvitationPresenter
      include Roar::JSON::HAL
      include Roar::Hypermedia
      include Grape::Roar::Representer

      property :id, type: String, desc: 'Invitation ID.'
      property :team_id, type: String, desc: 'Slack team ID.'
      property :email, type: String, desc: 'Invitation email.'

      link :self do |opts|
        request = Grape::Request.new(opts[:env])
        "#{request.base_url}/api/invitations/#{id}"
      end

      link :team do |opts|
        request = Grape::Request.new(opts[:env])
        "#{request.base_url}/api/teams/#{team_id}"
      end
    end
  end
end
