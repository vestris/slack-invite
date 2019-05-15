module Api
  module Endpoints
    class InvitationsEndpoint < Grape::API
      format :json

      namespace :invitations do
        desc 'Get an invitation.'
        params do
          requires :team_id, type: String
          requires :email, type: String
        end
        post do
          email = params[:email] # TODO: verify format
          team = Team.where(team_id: params[:team_id]).first || error!('Team Not Found', 404)
          Api::Middleware.logger.info "Inviting #{email} to team #{team}."
          # TODO: check if already member
          invitation = team.invitations.create!(email: email)
          invitation.send!
          present invitation, with: Api::Presenters::InvitationPresenter
        end
      end
    end
  end
end
