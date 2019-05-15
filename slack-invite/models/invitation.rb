class Invitation
  include Mongoid::Document
  include Mongoid::Timestamps

  field :email, type: String
  field :sent_at, type: DateTime
  field :ignored_at, type: DateTime

  belongs_to :team, index: true
  belongs_to :handled_by, class_name: 'User', inverse_of: nil, optional: true
  validates_presence_of :team

  index({ email: 1, team_id: 1 }, unique: true)

  def to_s
    "team=#{team_id}, email=#{email}"
  end

  def send!
    logger.info "SEND: #{self}"
    team.admin_slack_client.users_admin_invite(email: email)
    update_attributes!(sent_at: Time.now.utc)
  end

  def request!
    logger.info "REQUEST: #{self}"
    team.users.admins.each do |admin|
      admin.dm!(to_slack)
    end
  end

  def approve!(by)
    raise 'Invitation already handled.' if handled_by

    logger.info "APPROVE: #{self}, #{by}"
    update_attributes!(handled_by: by)
    send!
  end

  def ignore!(by)
    raise 'Invitation already handled.' if handled_by

    logger.info "IGNORE: #{self}, #{by}"
    update_attributes!(handled_by: by, ignored_at: Time.now.utc)
  end

  def to_slack
    if ignored_at
      {
        text: "Invitation request by #{email} was ignored by #{handled_by&.slack_mention} on #{ignored_at}."
      }
    elsif sent_at
      {
        text: "Invitation to #{email} was sent by #{handled_by&.slack_mention} on #{sent_at}."
      }
    else
      {
        text: "Hi, #{email} is asking to join #{team.name}!",
        attachments: [
          callback_id: 'invitation',
          fallback: 'You cannot approve invitations.',
          attachment_type: 'default',
          actions: [{
            name: 'approve',
            text: 'Approve',
            type: 'button',
            value: id.to_s
          }, {
            name: 'ignore',
            text: 'Ignore',
            type: 'button',
            value: id.to_s
          }]
        ]
      }
    end
  end
end
