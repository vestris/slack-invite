require 'spec_helper'

describe SlackInvite::Server do
  let(:team) { Fabricate(:team) }
  let(:server) { SlackInvite::Server.new(team: team) }
  let(:client) { server.send(:client) }
  context 'hooks' do
    let(:user) { Fabricate(:user, team: team) }
    it 'renames user' do
      client.send(:callback, Hashie::Mash.new(user: { id: user.user_id, name: 'updated' }), :user_change)
      expect(user.reload.user_name).to eq('updated')
    end
    it 'does not touch a user with the same name' do
      expect(User).to receive(:where).and_return([user])
      expect(user).to_not receive(:update_attributes!)
      client.send(:callback, Hashie::Mash.new(user: { id: user.user_id, name: user.user_name }), :user_change)
    end
  end
end
