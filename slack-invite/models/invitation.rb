class Invitation
  include Mongoid::Document
  include Mongoid::Timestamps

  field :email, type: String

  belongs_to :team, index: true
  validates_presence_of :team

  index({ email: 1, team_id: 1 }, unique: true)

  def to_s
    "team=#{team_id}, email=#{email}"
  end

  def send!
    team.slack_client.users_admin_invite(email: email)
  end
end
