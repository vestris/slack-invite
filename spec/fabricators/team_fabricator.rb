Fabricator(:team) do
  token { Fabricate.sequence(:team_token) { |i| "abc-#{i}" } }
  team_id { Fabricate.sequence(:team_id) { |i| "T#{i}" } }
  name { Faker::Lorem.word }
  api { true }
  created_at { Time.now - 2.weeks }
  domain { Faker::Internet.domain_word }
  icon { Faker::Avatar.image }
end
