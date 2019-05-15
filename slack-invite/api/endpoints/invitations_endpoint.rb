module Api
  module Endpoints
    class InvitationsEndpoint < Grape::API
      format :json

      namespace :invitations do
        desc 'Get an invitation.'
        params do
          requires :team_id, type: String
          optional :name, type: String
          requires :email, type: String
        end
        post do
          name = params[:name]
          email = params[:email] # TODO: verify format
          team = Team.where(team_id: params[:team_id]).first || error!('Team Not Found', 404)
          Api::Middleware.logger.info "Inviting #{email} to team #{team}."
          invitation = team.invitations.where(email: email).first || team.invitations.create!(name: name, email: email)
          team.require_approval ? invitation.request! : invitation.send!
          present invitation, with: Api::Presenters::InvitationPresenter
        end
      end
    end
  end
end
